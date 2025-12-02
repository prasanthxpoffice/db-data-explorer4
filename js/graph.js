(function () {
    var cy = null;

    var Graph = {
        init: function (containerId) {
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

            return 'data:image/svg+xml;utf8,' + encodeURIComponent(svg);
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

        addNodes: function (nodesData) {
            if (!cy) return;

            var nodesToAdd = [];
            var addedIds = new Set();

            nodesData.forEach(function (node) {
                var nodeId = Graph.normalizeId(node.NodeDataID);
                if (!nodeId) return;

                // Check for EXISTING node with same GroupNodeID and NodeValueID
                // Reverted to JS filter for robustness (handles type coercion)
                var existingNodes = cy.nodes().filter(function (ele) {
                    return ele.data('groupNodeId') == node.GroupNodeID &&
                        ele.data('nodeValueId') == node.NodeValueID;
                });

                if (existingNodes.length > 0) {
                    // MERGE into existing node
                    var existingNode = existingNodes[0];
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
                    }
                }
            });

            if (nodesToAdd.length > 0) {
                cy.add(nodesToAdd);
                cy.layout({ name: 'cose', animate: true }).run();
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
                // Find if target node already exists (visually)
                // Reverted to JS filter for robustness
                var existingTarget = cy.nodes().filter(function (ele) {
                    return ele.data('groupNodeId') == item.TargetGroupNodeID &&
                        ele.data('nodeValueId') == item.TargetNodeValueID;
                });

                var finalTargetId = targetId; // Default to the new ID

                if (existingTarget.length > 0) {
                    // Merge into existing
                    var existingNode = existingTarget[0];
                    finalTargetId = existingNode.id(); // Use the existing node's ID as target

                    var data = existingNode.data();
                    if (!data.allIds.includes(targetId)) {
                        data.allIds.push(targetId);
                        data.colors.push(item.TargetNodeColor || '#666');
                        Graph.updatePieData(data);
                        existingNode.data(data);

                        // Update Class
                        if (data.pieImage) existingNode.addClass('has-pie');
                        else existingNode.removeClass('has-pie');
                    }
                } else {
                    // Check if we already queued it in this batch
                    var key = item.TargetGroupNodeID + '-' + item.TargetNodeValueID;

                    // If not in graph AND not in batch, add it
                    if (!addedNodeKeys.has(key)) {
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
                        addedNodeKeys.add(key);
                    } else {
                        // It is in the batch, we need to find it in nodesToAdd and merge?
                        // For simplicity in this batch, we might skip merging within the same micro-batch 
                        // or just let the next pass handle it. 
                        // But to be correct, let's find it in nodesToAdd.
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
                                // Note: Can't easily update class on queued node object without helper, 
                                // but it will be handled when added or next update.
                                if (queuedNode.data.pieImage) queuedNode.classes = 'has-pie';
                            }
                        }
                    }
                }

                // --- 2. Handle Source Node Mapping ---
                // The sourceId returned by API is one of the internal IDs.
                // We need to find the VISUAL node that contains this sourceId.
                var sourceNode = cy.nodes().filter(function (ele) {
                    return ele.data('allIds') && ele.data('allIds').includes(sourceId);
                });

                var finalSourceId = sourceId;
                if (sourceNode.length > 0) {
                    finalSourceId = sourceNode[0].id();
                }

                // --- 3. Edge Merging ---
                // Check if ANY edge exists between finalSourceId and finalTargetId
                var existingEdges = cy.edges().filter(function (ele) {
                    return (ele.source().id() === finalSourceId && ele.target().id() === finalTargetId) ||
                        (ele.source().id() === finalTargetId && ele.target().id() === finalSourceId);
                });

                if (existingEdges.length === 0) {
                    // No visual edge exists, so add one
                    // We use the specific edgeId from DB, but visually it connects the merged nodes
                    edgesToAdd.push({
                        group: 'edges',
                        data: {
                            id: edgeId,
                            source: finalSourceId,
                            target: finalTargetId,
                            label: edgeLabel
                        }
                    });
                }
            });

            if (nodesToAdd.length > 0) cy.add(nodesToAdd);

            if (edgesToAdd.length > 0) {
                try {
                    cy.add(edgesToAdd);
                } catch (e) {
                    console.error("Error adding edges:", e);
                }
            }

            if (nodesToAdd.length > 0 || edgesToAdd.length > 0) {
                cy.layout({ name: 'cose', animate: true }).run();
            }
        },

        expandNextBatch: function () {
            if (!cy) return;

            var batchSize = parseInt($('#setting-batch-size').val()) || 50;
            var maxNeighbors = parseInt($('#setting-max-neighbors').val()) || 100;

            // Find nodes that are NOT fully expanded
            // Logic: A node is not fully expanded if it has IDs in allIds that are NOT in expandedIds
            var expandableNodes = cy.nodes().filter(function (ele) {
                var allIds = ele.data('allIds') || [];
                var expandedIds = ele.data('expandedIds') || [];
                // Check if there is any ID in allIds that is NOT in expandedIds
                return allIds.some(function (id) { return !expandedIds.includes(id); });
            });

            if (expandableNodes.length === 0) {
                alert("No unexpanded nodes found.");
                return;
            }

            // Take batch
            var batch = expandableNodes.slice(0, batchSize);

            // Collect IDs to expand (Granular Tracking)
            var idsToExpand = [];
            var nodeMap = new Map(); // Map SourceID -> Visual Node (to update state later)

            batch.forEach(function (ele) {
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
            if (cy) cy.elements().remove();
        }
    };

    window.Graph = Graph;

})();
