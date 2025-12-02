(function () {
    var cy = null;

    var Graph = {
        nodeLookup: {}, // Map: GroupNodeID-NodeValueID -> Cytoscape Node ID
        svgCache: {},   // Map: ColorKey -> SVG Data URI
        edgeLookup: new Set(), // Set: SourceID-TargetID (Visual IDs)
        expandableNodeIds: new Set(), // Set: Visual Node IDs that have unexpanded data

        init: function (containerId) {
            Graph.nodeLookup = {};
            Graph.svgCache = {};
            Graph.edgeLookup = new Set();
            Graph.expandableNodeIds = new Set();

            cy = cytoscape({
                container: $(containerId),
                style: [
                    {
                        selector: 'node',
                        style: {
                            'background-color': 'data(color)',
                            'label': 'data(label)',
                            'width': 'label',
                            'height': 'label',
                            'padding': '10px',
                            'shape': 'round-rectangle',
                            'font-size': 12,
                            'color': '#fff',
                            'text-valign': 'center',
                            'text-halign': 'center',
                            'text-wrap': 'wrap',
                            'text-max-width': 100,
                            'text-outline-width': 2,
                            'text-outline-color': 'data(color)'
                        }
                    },
                    {
                        selector: 'node.has-pie',
                        style: {
                            'background-image': 'data(pieImage)',
                            'background-fit': 'cover',
                            'background-opacity': 0 // Hide default background if pie is present
                        }
                    },
                    {
                        selector: 'edge',
                        style: {
                            'width': 2,
                            'line-color': '#ccc',
                            'target-arrow-color': '#ccc',
                            'target-arrow-shape': 'triangle',
                            'curve-style': 'bezier',
                            'label': 'data(label)',
                            'font-size': 10,
                            'text-rotation': 'autorotate',
                            'text-background-opacity': 1,
                            'text-background-color': '#fff',
                            'text-background-shape': 'round-rectangle'
                        }
                    }
                ],
                layout: {
                    name: 'grid',
                    rows: 1
                }
            });
        },

        normalizeId: function (id) {
            return String(id).trim();
        },

        // Helper to generate SVG Data URI for Pie Chart
        generatePieSVG: function (colors) {
            if (!colors || colors.length === 0) return null;
            if (colors.length === 1) return null; // Single color, use default background

            // Cache Key: Sorted colors joined by comma
            var cacheKey = colors.slice().sort().join(',');
            if (Graph.svgCache[cacheKey]) {
                return Graph.svgCache[cacheKey];
            }

            var size = 100;
            var center = size / 2;
            var radius = size / 2;
            var total = colors.length;
            var sliceAngle = (2 * Math.PI) / total;

            var paths = [];
            var startAngle = 0;

            colors.forEach(function (color) {
                var endAngle = startAngle + sliceAngle;

                // Calculate path coordinates
                var x1 = center + radius * Math.cos(startAngle);
                var y1 = center + radius * Math.sin(startAngle);
                var x2 = center + radius * Math.cos(endAngle);
                var y2 = center + radius * Math.sin(endAngle);

                // SVG Path command
                var d = [
                    "M", center, center,
                    "L", x1, y1,
                    "A", radius, radius, 0, 0, 1, x2, y2,
                    "Z"
                ].join(" ");

                paths.push('<path d="' + d + '" fill="' + color + '" />');
                startAngle = endAngle;
            });

            var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size + '" viewBox="0 0 ' + size + ' ' + size + '">' +
                paths.join('') +
                '</svg>';

            var dataUri = 'data:image/svg+xml;utf8,' + encodeURIComponent(svg);
            Graph.svgCache[cacheKey] = dataUri;
            return dataUri;
        },

        // Helper to update pie chart data based on colors array
        updatePieData: function (nodeData) {
            var colors = nodeData.colors || [];

            if (colors.length > 1) {
                var svgDataUri = Graph.generatePieSVG(colors);
                nodeData.pieImage = svgDataUri;
                nodeData.color = 'transparent'; // Hide base color
            } else {
                nodeData.pieImage = null;
                // Keep original color if single
                if (colors.length === 1) nodeData.color = colors[0];
            }
        },

        // Centralized Layout Helper
        runLayout: function (newElements) {
            if (!cy) return;

            // If it's the very first load (total nodes == new nodes), run global layout
            var isFirstLoad = (cy.nodes().length === newElements.length);

            if (isFirstLoad) {
                var layout = cy.layout({
                    name: 'cose',
                    animate: true,
                    randomize: true,
                    fit: true,
                    padding: 50
                });
                layout.run();
            } else {
                // Incremental Layout
                // 1. Run layout ONLY on new elements + neighbors
                var layoutEles = newElements.union(newElements.neighborhood());

                var layout = layoutEles.layout({
                    name: 'cose',
                    animate: true,
                    randomize: false, // Keep existing nodes stable
                    fit: false // Don't fit the *layout* (we'll fit global later)
                });

                // 2. After layout finishes, smoothly fit the ENTIRE graph
                layout.one('layoutstop', function () {
                    cy.animate({
                        fit: {
                            eles: cy.elements(),
                            padding: 50
                        },
                        duration: 500,
                        easing: 'ease-in-out-cubic'
                    });
                });

                layout.run();
            }
        },

        addNodes: function (nodesData) {
            if (!cy) return;

            var nodesToAdd = [];
            var addedIds = new Set();

            nodesData.forEach(function (node) {
                var nodeId = Graph.normalizeId(node.NodeDataID);
                if (!nodeId) return;

                // Lookup Key
                var lookupKey = node.GroupNodeID + '-' + node.NodeValueID;
                var existingNodeId = Graph.nodeLookup[lookupKey];

                if (existingNodeId) {
                    // MERGE into existing node
                    var existingNode = cy.getElementById(existingNodeId);
                    if (existingNode.length > 0) {
                        var data = existingNode.data();

                        // Add ID if not present
                        if (!data.allIds.includes(nodeId)) {
                            data.allIds.push(nodeId);
                            data.colors.push(node.ColumnColor || '#666');

                            // Update Pie Data
                            Graph.updatePieData(data);
                            existingNode.data(data); // Apply updates

                            // Update Class
                            if (data.pieImage) existingNode.addClass('has-pie');
                            else existingNode.removeClass('has-pie');

                            // Mark as expandable since we added new data
                            Graph.expandableNodeIds.add(existingNodeId);
                        }
                    }
                } else {
                    // CREATE new node
                    if (cy.getElementById(nodeId).length === 0 && !addedIds.has(nodeId)) {
                        var newNodeData = {
                            id: nodeId,
                            label: node.NodeValue,
                            color: node.ColumnColor || '#666',
                            groupNodeId: node.GroupNodeID,
                            nodeValueId: node.NodeValueID,
                            nodeValueDate: node.NodeValueDate,
                            isExpanded: false,

                            // Merging Properties
                            allIds: [nodeId],
                            colors: [node.ColumnColor || '#666'],
                            expandedIds: [] // Track which internal IDs are expanded
                        };

                        Graph.updatePieData(newNodeData);

                        nodesToAdd.push({
                            group: 'nodes',
                            data: newNodeData,
                            classes: newNodeData.pieImage ? 'has-pie' : ''
                        });
                        addedIds.add(nodeId);

                        // Update Lookup
                        Graph.nodeLookup[lookupKey] = nodeId;

                        // Mark as expandable
                        Graph.expandableNodeIds.add(nodeId);
                    }
                }
            });

            if (nodesToAdd.length > 0) {
                var newEles = cy.add(nodesToAdd);
                Graph.runLayout(newEles);
            }
        },

        addExpansionResults: function (results) {
            if (!cy) return;

            var nodesToAdd = [];
            var edgesToAdd = [];

            // We need to track what we've added in this batch to avoid dupes within the batch
            var addedNodeKeys = new Set(); // Key: GroupNodeID-NodeValueID

            results.forEach(function (item) {
                var sourceNodeID = item.SourceNodeDataID || item.SourceNodeID;
                var targetNodeID = item.TargetNodeDataID || item.TargetNodeID;
                var edgeID = item.RelationDataID || item.EdgeID;
                var edgeLabel = item.Relation || item.EdgeLabel;

                if (!sourceNodeID || !targetNodeID || !edgeID) return;

                var targetId = Graph.normalizeId(targetNodeID);
                var sourceId = Graph.normalizeId(sourceNodeID); // This is the specific ID that was expanded
                var edgeId = Graph.normalizeId(edgeID);

                // --- 1. Handle Target Node Merging ---
                var lookupKey = item.TargetGroupNodeID + '-' + item.TargetNodeValueID;
                var existingNodeId = Graph.nodeLookup[lookupKey];

                var finalTargetId = targetId; // Default to the new ID

                if (existingNodeId) {
                    // Merge into existing
                    var existingNode = cy.getElementById(existingNodeId);
                    if (existingNode.length > 0) {
                        finalTargetId = existingNodeId; // Use the existing node's ID as target

                        var data = existingNode.data();
                        if (!data.allIds.includes(targetId)) {
                            data.allIds.push(targetId);
                            data.colors.push(item.TargetNodeColor || '#666');
                            Graph.updatePieData(data);
                            existingNode.data(data);

                            // Update Class
                            if (data.pieImage) existingNode.addClass('has-pie');
                            else existingNode.removeClass('has-pie');

                            // Mark as expandable
                            Graph.expandableNodeIds.add(existingNodeId);
                        }
                    }
                } else {
                    // Check if we already queued it in this batch
                    if (!addedNodeKeys.has(lookupKey)) {
                        var newNodeData = {
                            id: targetId,
                            label: item.TargetNodeValue,
                            color: item.TargetNodeColor || '#666',
                            groupNodeId: item.TargetGroupNodeID,
                            nodeValueId: item.TargetNodeValueID,
                            nodeValueDate: item.TargetNodeValueDate,
                            isExpanded: false,
                            allIds: [targetId],
                            colors: [item.TargetNodeColor || '#666'],
                            expandedIds: []
                        };
                        Graph.updatePieData(newNodeData);

                        nodesToAdd.push({
                            group: 'nodes',
                            data: newNodeData,
                            classes: newNodeData.pieImage ? 'has-pie' : ''
                        });
                        addedNodeKeys.add(lookupKey);

                        // Optimistically update lookup for this batch
                        Graph.nodeLookup[lookupKey] = targetId;

                        Graph.expandableNodeIds.add(targetId);
                    } else {
                        // It is in the batch
                        var queuedNode = nodesToAdd.find(function (n) {
                            return n.data.groupNodeId == item.TargetGroupNodeID &&
                                n.data.nodeValueId == item.TargetNodeValueID;
                        });
                        if (queuedNode) {
                            finalTargetId = queuedNode.data.id;
                            if (!queuedNode.data.allIds.includes(targetId)) {
                                queuedNode.data.allIds.push(targetId);
                                queuedNode.data.colors.push(item.TargetNodeColor || '#666');
                                Graph.updatePieData(queuedNode.data);
                                if (queuedNode.data.pieImage) queuedNode.classes = 'has-pie';
                            }
                        }
                    }
                }

                // --- 2. Handle Source Node Mapping ---

                var sourceNode = cy.nodes().filter(function (ele) {
                    return ele.data('allIds') && ele.data('allIds').includes(sourceId);
                });

                var finalSourceId = sourceId;
                if (sourceNode.length > 0) {
                    finalSourceId = sourceNode[0].id();
                }

                // --- 3. Edge Merging ---
                // Check if ANY edge exists between finalSourceId and finalTargetId
                // Optimized: Use Set Lookup
                var edgeKey1 = finalSourceId + '-' + finalTargetId;
                var edgeKey2 = finalTargetId + '-' + finalSourceId; // Assuming undirected visual check

                if (!Graph.edgeLookup.has(edgeKey1) && !Graph.edgeLookup.has(edgeKey2)) {
                    // No visual edge exists, so add one
                    edgesToAdd.push({
                        group: 'edges',
                        data: {
                            id: edgeId,
                            source: finalSourceId,
                            target: finalTargetId,
                            label: edgeLabel
                        }
                    });
                    Graph.edgeLookup.add(edgeKey1);
                    Graph.edgeLookup.add(edgeKey2);
                }
            });

            var newEles = cy.collection();

            if (nodesToAdd.length > 0) {
                newEles = newEles.union(cy.add(nodesToAdd));
            }

            if (edgesToAdd.length > 0) {
                try {
                    newEles = newEles.union(cy.add(edgesToAdd));
                } catch (e) {
                    console.error("Error adding edges:", e);
                }
            }

            if (newEles.length > 0) {
                Graph.runLayout(newEles);
            }
        },

        expandNextBatch: function () {
            if (!cy) return;

            var batchSize = parseInt($('#setting-batch-size').val()) || 50;
            var maxNeighbors = parseInt($('#setting-max-neighbors').val()) || 100;

            // Find nodes that are NOT fully expanded
            // Optimized: Use Graph.expandableNodeIds Set
            var expandableNodes = [];
            var idsToRemove = []; // IDs that are actually fully expanded and should be removed from Set

            // Iterate the Set
            // Note: Sets are iterable in insertion order
            for (var id of Graph.expandableNodeIds) {
                if (expandableNodes.length >= batchSize) break;

                var node = cy.getElementById(id);
                if (node.length === 0) {
                    idsToRemove.push(id); // Node removed from graph?
                    continue;
                }

                var allIds = node.data('allIds') || [];
                var expandedIds = node.data('expandedIds') || [];

                // Check if truly expandable
                var hasNewIds = allIds.some(function (x) { return !expandedIds.includes(x); });

                if (hasNewIds) {
                    expandableNodes.push(node);
                } else {
                    idsToRemove.push(id); // Fully expanded
                }
            }

            // Cleanup Set
            idsToRemove.forEach(function (id) { Graph.expandableNodeIds.delete(id); });

            if (expandableNodes.length === 0) {
                if (Graph.expandableNodeIds.size === 0) {
                    alert("No unexpanded nodes found.");
                } else {
                    alert("No unexpanded nodes found in this pass.");
                }
                return;
            }

            // Collect IDs to expand (Granular Tracking)
            var idsToExpand = [];
            var nodeMap = new Map(); // Map SourceID -> Visual Node (to update state later)

            expandableNodes.forEach(function (ele) {
                var allIds = ele.data('allIds') || [];
                var expandedIds = ele.data('expandedIds') || [];

                var newIds = allIds.filter(function (id) { return !expandedIds.includes(id); });

                newIds.forEach(function (id) {
                    idsToExpand.push(id);
                    nodeMap.set(id, ele);
                });
            });

            if (idsToExpand.length === 0) {
                alert("No new data to expand.");
                return;
            }

            var filters = [];
            var $grid = $('#legends-grid');
            if ($grid.length > 0) {
                var selectedRowIds = $grid.jqGrid('getGridParam', 'selarrrow');
                if (selectedRowIds) {
                    selectedRowIds.forEach(function (rowId) {
                        var $row = $grid.find('tr#' + rowId);
                        var fromDate = $row.find('.from-date').val();
                        var toDate = $row.find('.to-date').val();

                        function parseDate(d, isFrom) {
                            if (!d) return isFrom ? '1900-01-01' : '9999-12-31';
                            var parts = d.split('/');
                            if (parts.length === 3) return parts[2] + '-' + parts[1] + '-' + parts[0];
                            return isFrom ? '1900-01-01' : '9999-12-31';
                        }

                        filters.push({
                            NodeID: parseInt(rowId),
                            FromDate: parseDate(fromDate, true),
                            ToDate: parseDate(toDate, false)
                        });
                    });
                }
            }

            var config = window.parent.APP_CONFIG;
            if (!config) return;

            var payload = {
                ViewGroupID: 1,
                SourceNodeDataIDs: idsToExpand, // Send only new IDs
                FilterNodes: filters,
                MaxNeighbors: maxNeighbors,
                Lang: config.Lang
            };

            var viewGroupId = $('#view-groups-dropdown').val();
            if (viewGroupId) payload.ViewGroupID = parseInt(viewGroupId);

            $.ajax({
                url: config.api.nodesExpand.path,
                method: config.api.nodesExpand.method,
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function (data) {
                    Graph.addExpansionResults(data);

                    // Update State: Mark sent IDs as expanded
                    idsToExpand.forEach(function (id) {
                        var node = nodeMap.get(id);
                        if (node) {
                            var expandedIds = node.data('expandedIds') || [];
                            if (!expandedIds.includes(id)) {
                                expandedIds.push(id);
                                node.data('expandedIds', expandedIds);
                            }

                            // Check if fully expanded
                            var allIds = node.data('allIds');
                            if (allIds.length === expandedIds.length) {
                                node.data('isExpanded', true);
                                // Remove from expandable set
                                Graph.expandableNodeIds.delete(node.id());
                            }
                        }
                    });
                },
                error: function (err) {
                    console.error("Expansion failed", err);
                    alert("Expansion failed.");
                }
            });
        },

        clear: function () {
            Graph.nodeLookup = {};
            Graph.svgCache = {};
            Graph.edgeLookup = new Set();
            Graph.expandableNodeIds = new Set();
            if (cy) cy.elements().remove();
        }
    };

    window.Graph = Graph;

})();
