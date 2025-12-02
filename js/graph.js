(function () {
    var cy = null;

    // Optimization: String Interner (Symbol Table)
    var Interner = {
        map: new Map(), // String -> Int
        pool: [],       // Int -> String
        get: function (str) {
            if (str === null || str === undefined) return 0;
            var s = String(str).trim();
            if (s === "") return 0;

            var id = Interner.map.get(s);
            if (id !== undefined) return id;

            id = Interner.pool.length + 1;
            Interner.map.set(s, id);
            Interner.pool.push(s);
            return id;
        },
        resolve: function (id) {
            if (!id || id <= 0) return null;
            return Interner.pool[id - 1];
        },
        clear: function () {
            Interner.map = new Map();
            Interner.pool = [];
        }
    };

    // Optimization: Bitwise Flags
    var FLAGS = {
        EXPANDED: 1,
        HAS_PIE: 2
    };

    // Optimization: Shape Stabilization (Factory)
    // Ensures all Node Data objects have the exact same Hidden Class
    function createNodeData(id, label, color, group, value, date, allIds, colors, expandedIds) {
        return {
            id: id,                 // String (for Cytoscape)
            label: label,           // String
            color: color,           // String
            groupNodeId: group,     // Int
            nodeValueId: value,     // Int
            nodeValueDate: date,    // String
            allIds: allIds,         // Array<Int>
            colors: colors,         // Array<String>
            expandedIds: expandedIds, // Array<Int>
            pieImage: null,         // String (Always present for stability)
            flags: 0,               // Int (Bitmask)
            legendId: 0             // Int (For filtering)
        };
    }

    var Graph = {
        nodeLookup: new Map(), // Nested Map: GroupInt -> Map<ValueInt, NodeInt>
        internalIdLookup: new Map(), // Map: NodeDataInt (Internal) -> NodeInt (Visual)
        idSets: new Map(), // Map: NodeInt -> Set<InternalInt>
        svgCache: {},   // Map: ColorKey -> SVG Data URI
        adjacencyList: new Map(), // Map: SourceInt -> Set<TargetInt>
        expandableNodeIds: new Set(), // Set: NodeInt
        isExpanding: false, // Mutex

        init: function (containerId) {
            Graph.clear();

            cy = cytoscape({
                container: $(containerId),
                textureOnViewport: true,
                hideEdgesOnViewport: true,
                pixelRatio: 1,
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
                            'min-zoomed-font-size': 8
                        }
                    },
                    {
                        selector: 'node:selected',
                        style: {
                            'text-wrap': 'wrap',
                            'text-max-width': 100,
                            'text-outline-width': 2,
                            'text-outline-color': 'data(color)',
                            'z-index': 9999
                        }
                    },
                    {
                        selector: 'node.has-pie',
                        style: {
                            'background-image': 'data(pieImage)',
                            'background-fit': 'cover',
                            'background-opacity': 0
                        }
                    },
                    {
                        selector: 'node.expanded',
                        style: {
                            'border-color': '#333',
                            'border-width': 2
                        }
                    },
                    {
                        selector: 'node.hidden',
                        style: {
                            'display': 'none'
                        }
                    },
                    {
                        style: {
                            'display': 'none'
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
                            'text-background-shape': 'round-rectangle',
                            'min-zoomed-font-size': 8
                        }
                    },
                    {
                        selector: 'node.path-highlight',
                        style: {
                            'border-color': 'data(pathColor)',
                            'border-width': 4,
                            'z-index': 9999
                        }
                    },
                    {
                        selector: 'edge.path-highlight',
                        style: {
                            'width': 4,
                            'line-color': 'data(pathColor)',
                            'target-arrow-color': 'data(pathColor)',
                            'source-arrow-color': 'data(pathColor)',
                            'z-index': 9999
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
            return id;
        },

        generatePieSVG: function (colors) {
            if (!colors || colors.length === 0) return null;
            if (colors.length === 1) return null;

            if (Object.keys(Graph.svgCache).length > 1000) {
                Graph.svgCache = {};
            }

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
                var x1 = center + radius * Math.cos(startAngle);
                var y1 = center + radius * Math.sin(startAngle);
                var x2 = center + radius * Math.cos(endAngle);
                var y2 = center + radius * Math.sin(endAngle);

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

        updatePieData: function (nodeData) {
            var colors = nodeData.colors || [];
            if (colors.length > 1) {
                var svgDataUri = Graph.generatePieSVG(colors);
                nodeData.pieImage = svgDataUri;
                nodeData.color = 'transparent';
                nodeData.flags |= FLAGS.HAS_PIE; // Set Flag
            } else {
                nodeData.pieImage = null;
                if (colors.length === 1) nodeData.color = colors[0];
                nodeData.flags &= ~FLAGS.HAS_PIE; // Clear Flag
            }
        },
        runLayout: function (newElements) {
            if (!cy) return;
            try {
                // Safety: Filter out elements that might have been removed or are invalid
                var validElements = newElements.filter(function (ele) {
                    return ele.inside();
                });

                if (validElements.length === 0) return;

                var totalNodes = cy.nodes().length;
                var newNodes = validElements.nodes().length;

                // Heuristic: If we are adding the first batch of nodes, or the graph is very small, run full layout.
                var isFirstLoad = (totalNodes === newNodes) || (totalNodes < 10);

                var shouldAnimate = true;
                if (validElements.length > 100) {
                    shouldAnimate = false;
                }

                var layoutConfig = {
                    name: 'cose',
                    animate: shouldAnimate,
                    randomize: false,
                    fit: false,
                    idealEdgeLength: 100,
                    nodeRepulsion: 400000,
                    numIter: 1000,
                    padding: 50,
                    componentSpacing: 40,
                    nodeDimensionsIncludeLabels: true
                };

                if (isFirstLoad) {
                    layoutConfig.randomize = true;
                    layoutConfig.fit = true;
                    cy.layout(layoutConfig).run();
                } else {
                    // Incremental layout: Include neighbors to settle new nodes relative to existing ones
                    var layoutEles = validElements.union(validElements.neighborhood());

                    // Double check validity of layout elements and positions
                    var validLayoutEles = layoutEles.filter(function (ele) {
                        if (!ele.inside()) return false;
                        if (ele.isNode()) {
                            var pos = ele.position();
                            if (!pos || typeof pos.x !== 'number' || typeof pos.y !== 'number') {
                                // Fix invalid position
                                ele.position({ x: 0, y: 0 });
                            }
                            return true;
                        }
                        return false; // Edges handled below
                    });

                    // Strict Edge Check: Ensure both source and target are in the validLayoutEles set
                    var validEdges = layoutEles.edges().filter(function (edge) {
                        if (!edge.inside()) return false;
                        var source = edge.source();
                        var target = edge.target();
                        // Check if source and target are valid AND included in our layout set
                        var sourceValid = validLayoutEles.has(source);
                        var targetValid = validLayoutEles.has(target);
                        return sourceValid && targetValid;
                    });

                    // Combine valid nodes and valid edges
                    var finalLayoutEles = validLayoutEles.union(validEdges);

                    if (finalLayoutEles.length > 0) {
                        // Use Core Layout with 'eles' option for better stability
                        layoutConfig.eles = finalLayoutEles;
                        var layoutInstance = cy.layout(layoutConfig);

                        layoutInstance.one('layoutstop', function () {
                            // Smart Fit: Only fit if the new nodes are off-screen or graph grew significantly
                            cy.animate({
                                fit: {
                                    eles: cy.elements(),
                                    padding: 50
                                },
                                duration: 500,
                                easing: 'ease-in-out-cubic'
                            });
                        });
                        layoutInstance.run();
                    }
                }
            } catch (e) {
                console.error("Layout failed:", e);
            }
        },

        addNodes: function (nodesData) {
            if (!cy) return;

            var chunkSize = 500;
            var index = 0;
            var total = nodesData.length;
            var allNewEles = cy.collection();

            function processChunk() {
                var chunkEnd = Math.min(index + chunkSize, total);
                var nodesToAdd = [];
                var addedIds = new Set();

                cy.batch(function () {
                    for (var i = index; i < chunkEnd; i++) {
                        var node = nodesData[i];

                        var nodeIdInt = Interner.get(node.NodeDataID);
                        if (!nodeIdInt) continue;

                        var groupIdInt = Interner.get(node.GroupNodeID);
                        var valueIdInt = Interner.get(node.NodeValueID);

                        var groupMap = Graph.nodeLookup.get(groupIdInt);
                        var existingNodeIdInt = groupMap ? groupMap.get(valueIdInt) : undefined;

                        if (existingNodeIdInt) {
                            // MERGE
                            var existingNodeIdStr = Interner.resolve(existingNodeIdInt);
                            var existingNode = cy.getElementById(existingNodeIdStr);

                            if (existingNode.length > 0) {
                                var data = existingNode.data();
                                var idSet = Graph.idSets.get(existingNodeIdInt);

                                if (!idSet.has(nodeIdInt)) {
                                    data.allIds.push(nodeIdInt);
                                    idSet.add(nodeIdInt);

                                    data.colors.push(node.ColumnColor || '#666');
                                    Graph.updatePieData(data);

                                    // Clear Expanded Flag since we added new data
                                    data.flags &= ~FLAGS.EXPANDED;
                                    existingNode.removeClass('expanded');

                                    existingNode.data(data);

                                    // Check Flag for Class
                                    if (data.flags & FLAGS.HAS_PIE) existingNode.addClass('has-pie');
                                    else existingNode.removeClass('has-pie');

                                    Graph.expandableNodeIds.add(existingNodeIdInt);
                                    Graph.internalIdLookup.set(nodeIdInt, existingNodeIdInt);
                                }
                            }
                        } else {
                            // CREATE
                            if (!addedIds.has(nodeIdInt)) {
                                var nodeIdStr = Interner.resolve(nodeIdInt);

                                if (cy.getElementById(nodeIdStr).length === 0) {
                                    // Optimization: Use Factory
                                    var newNodeData = createNodeData(
                                        nodeIdStr,
                                        node.NodeValue,
                                        node.ColumnColor || '#666',
                                        groupIdInt,
                                        valueIdInt,
                                        node.NodeValueDate,
                                        [nodeIdInt],
                                        [node.ColumnColor || '#666'],
                                        []
                                    );

                                    // Set Legend ID (NodeID from DB)
                                    newNodeData.legendId = parseInt(node.NodeID) || 0;

                                    Graph.updatePieData(newNodeData);

                                    nodesToAdd.push({
                                        group: 'nodes',
                                        data: newNodeData,
                                        classes: (newNodeData.flags & FLAGS.HAS_PIE) ? 'has-pie' : ''
                                    });
                                    addedIds.add(nodeIdInt);

                                    if (!Graph.nodeLookup.has(groupIdInt)) {
                                        Graph.nodeLookup.set(groupIdInt, new Map());
                                    }
                                    Graph.nodeLookup.get(groupIdInt).set(valueIdInt, nodeIdInt);

                                    Graph.internalIdLookup.set(nodeIdInt, nodeIdInt);
                                    Graph.idSets.set(nodeIdInt, new Set([nodeIdInt]));
                                    Graph.expandableNodeIds.add(nodeIdInt);
                                }
                            }
                        }
                    }
                });

                if (nodesToAdd.length > 0) {
                    var chunkEles = cy.add(nodesToAdd);
                    allNewEles = allNewEles.union(chunkEles);
                }

                index += chunkSize;

                if (index < total) {
                    requestAnimationFrame(processChunk);
                } else {
                    if (allNewEles.length > 0) {
                        Graph.runLayout(allNewEles);
                    }
                }
            }

            processChunk();
        },

        addExpansionResults: function (results) {
            if (!cy) return;

            var nodesToAdd = [];
            var edgesToAdd = [];

            var uniqueTargetsMap = new Map();

            results.forEach(function (item) {
                if (!item.TargetNodeDataID && !item.TargetNodeID) return;

                var groupIdInt = Interner.get(item.TargetGroupNodeID);
                var valueIdInt = Interner.get(item.TargetNodeValueID);

                if (!uniqueTargetsMap.has(groupIdInt)) {
                    uniqueTargetsMap.set(groupIdInt, new Map());
                }
                var groupMap = uniqueTargetsMap.get(groupIdInt);
                if (!groupMap.has(valueIdInt)) {
                    groupMap.set(valueIdInt, item);
                }
            });

            cy.batch(function () {
                // --- Pass 2: Process Unique Nodes ---
                uniqueTargetsMap.forEach(function (groupMap, groupIdInt) {
                    groupMap.forEach(function (item, valueIdInt) {
                        var targetNodeID = item.TargetNodeDataID || item.TargetNodeID;
                        var targetIdInt = Interner.get(targetNodeID);

                        var lookupGroupMap = Graph.nodeLookup.get(groupIdInt);
                        var existingNodeIdInt = lookupGroupMap ? lookupGroupMap.get(valueIdInt) : undefined;

                        if (existingNodeIdInt) {
                            // Merge
                            var existingNodeIdStr = Interner.resolve(existingNodeIdInt);
                            var existingNode = cy.getElementById(existingNodeIdStr);

                            if (existingNode.length > 0) {
                                var data = existingNode.data();
                                var idSet = Graph.idSets.get(existingNodeIdInt);

                                if (!idSet.has(targetIdInt)) {
                                    data.allIds.push(targetIdInt);
                                    idSet.add(targetIdInt);

                                    data.colors.push(item.TargetNodeColor || '#666');
                                    Graph.updatePieData(data);

                                    // Clear Expanded Flag since we added new data
                                    data.flags &= ~FLAGS.EXPANDED;
                                    existingNode.removeClass('expanded');

                                    existingNode.data(data);

                                    if (data.flags & FLAGS.HAS_PIE) existingNode.addClass('has-pie');
                                    else existingNode.removeClass('has-pie');

                                    Graph.expandableNodeIds.add(existingNodeIdInt);
                                    Graph.internalIdLookup.set(targetIdInt, existingNodeIdInt);
                                }
                            }
                        } else {
                            // Create
                            var targetIdStr = Interner.resolve(targetIdInt);

                            // Optimization: Use Factory
                            var newNodeData = createNodeData(
                                targetIdStr,
                                item.TargetNodeValue,
                                item.TargetNodeColor || '#666',
                                groupIdInt,
                                valueIdInt,
                                item.TargetNodeValueDate,
                                [targetIdInt],
                                [item.TargetNodeColor || '#666'],
                                []
                            );

                            // Set Legend ID (TargetNodeID from DB)
                            newNodeData.legendId = parseInt(item.TargetNodeID) || 0;

                            Graph.updatePieData(newNodeData);

                            Graph.updatePieData(newNodeData);

                            // Initial Position Logic: Place near source if possible
                            var sourceNodeID = item.SourceNodeDataID || item.SourceNodeID;
                            var initialPos = { x: 0, y: 0 };
                            if (sourceNodeID) {
                                var sourceIdInt = Interner.get(sourceNodeID);
                                var finalSourceIdInt = Graph.internalIdLookup.get(sourceIdInt);
                                if (finalSourceIdInt) {
                                    var sourceNode = cy.getElementById(Interner.resolve(finalSourceIdInt));
                                    if (sourceNode.length > 0) {
                                        var pos = sourceNode.position();
                                        // Randomize slightly to avoid stacking
                                        initialPos = {
                                            x: pos.x + (Math.random() * 100 - 50),
                                            y: pos.y + (Math.random() * 100 - 50)
                                        };
                                    }
                                }
                            }

                            nodesToAdd.push({
                                group: 'nodes',
                                data: newNodeData,
                                position: initialPos,
                                classes: (newNodeData.flags & FLAGS.HAS_PIE) ? 'has-pie' : ''
                            });

                            if (!Graph.nodeLookup.has(groupIdInt)) {
                                Graph.nodeLookup.set(groupIdInt, new Map());
                            }
                            Graph.nodeLookup.get(groupIdInt).set(valueIdInt, targetIdInt);

                            Graph.internalIdLookup.set(targetIdInt, targetIdInt);
                            Graph.idSets.set(targetIdInt, new Set([targetIdInt]));
                            Graph.expandableNodeIds.add(targetIdInt);
                        }
                    });
                });

                // --- Pass 3: Process Edges ---
                results.forEach(function (item) {
                    var sourceNodeID = item.SourceNodeDataID || item.SourceNodeID;
                    var targetNodeID = item.TargetNodeDataID || item.TargetNodeID;
                    var edgeID = item.RelationDataID || item.EdgeID;
                    var edgeLabel = item.Relation || item.EdgeLabel;

                    if (!sourceNodeID || !targetNodeID || !edgeID) return;

                    var sourceIdInt = Interner.get(sourceNodeID);
                    var targetIdInt = Interner.get(targetNodeID);
                    var edgeIdStr = String(edgeID).trim();

                    var finalSourceIdInt = Graph.internalIdLookup.get(sourceIdInt);
                    var finalTargetIdInt = Graph.internalIdLookup.get(targetIdInt);

                    // Safety Check: Ensure Source Node exists (Old or New)
                    if (!finalSourceIdInt) {
                        // Fallback: Scan existing nodes (expensive, but rare)
                        var sourceNode = cy.nodes().filter(function (ele) {
                            var allIds = ele.data('allIds');
                            return allIds && allIds.includes(sourceIdInt);
                        });
                        if (sourceNode.length > 0) {
                            finalSourceIdInt = Interner.get(sourceNode[0].id());
                            Graph.internalIdLookup.set(sourceIdInt, finalSourceIdInt);
                        } else {
                            // If not found, we can't add the edge
                            return;
                        }
                    }

                    if (!finalTargetIdInt) finalTargetIdInt = targetIdInt;

                    var hasEdge = false;
                    if (Graph.adjacencyList.has(finalSourceIdInt)) {
                        if (Graph.adjacencyList.get(finalSourceIdInt).has(finalTargetIdInt)) hasEdge = true;
                    }
                    if (!hasEdge && Graph.adjacencyList.has(finalTargetIdInt)) {
                        if (Graph.adjacencyList.get(finalTargetIdInt).has(finalSourceIdInt)) hasEdge = true;
                    }

                    if (!hasEdge) {
                        var finalSourceIdStr = Interner.resolve(finalSourceIdInt);
                        var finalTargetIdStr = Interner.resolve(finalTargetIdInt);

                        edgesToAdd.push({
                            group: 'edges',
                            data: {
                                id: edgeIdStr,
                                source: finalSourceIdStr,
                                target: finalTargetIdStr,
                                label: edgeLabel
                            }
                        });

                        if (!Graph.adjacencyList.has(finalSourceIdInt)) {
                            Graph.adjacencyList.set(finalSourceIdInt, new Set());
                        }
                        Graph.adjacencyList.get(finalSourceIdInt).add(finalTargetIdInt);

                        if (!Graph.adjacencyList.has(finalTargetIdInt)) {
                            Graph.adjacencyList.set(finalTargetIdInt, new Set());
                        }
                        Graph.adjacencyList.get(finalTargetIdInt).add(finalSourceIdInt);
                    }
                });
            });

            var allEles = [];
            if (nodesToAdd.length > 0) allEles = allEles.concat(nodesToAdd);
            if (edgesToAdd.length > 0) allEles = allEles.concat(edgesToAdd);

            if (allEles.length > 0) {
                try {
                    var addedEles = cy.add(allEles);
                    Graph.runLayout(addedEles);
                } catch (e) {
                    console.error("Error adding elements or running layout:", e);
                }
            }
        },

        expandNextBatch: function () {
            if (!cy) return;
            if (Graph.isExpanding) return;
            Graph.isExpanding = true;

            var batchSize = parseInt($('#setting-batch-size').val()) || 50;
            var maxNeighbors = parseInt($('#setting-max-neighbors').val()) || 100;

            var expandableNodes = [];
            var idsToRemove = [];

            for (var idInt of Graph.expandableNodeIds) {
                if (expandableNodes.length >= batchSize) break;

                var idStr = Interner.resolve(idInt);
                var node = cy.getElementById(idStr);
                if (node.length === 0) {
                    idsToRemove.push(idInt);
                    continue;
                }

                var allIds = node.data('allIds') || [];
                var expandedIds = node.data('expandedIds') || [];

                if (allIds.length > expandedIds.length) {
                    expandableNodes.push(node);
                } else {
                    idsToRemove.push(idInt);
                }
            }

            idsToRemove.forEach(function (id) { Graph.expandableNodeIds.delete(id); });

            if (expandableNodes.length === 0) {
                Graph.isExpanding = false;
                if (Graph.expandableNodeIds.size === 0) {
                    alert(window.i18n.get('graph.noUnexpanded'));
                } else {
                    alert(window.i18n.get('graph.noUnexpandedPass'));
                }
                return;
            }

            var idsToExpand = [];
            var nodeMap = new Map();

            expandableNodes.forEach(function (ele) {
                var allIds = ele.data('allIds') || [];
                var expandedIds = ele.data('expandedIds') || [];
                var expandedSet = new Set(expandedIds);

                var newIds = allIds.filter(function (id) { return !expandedSet.has(id); });

                newIds.forEach(function (idInt) {
                    idsToExpand.push(Interner.resolve(idInt));
                    nodeMap.set(idInt, ele);
                });
            });

            if (idsToExpand.length === 0) {
                Graph.isExpanding = false;
                alert(window.i18n.get('graph.noNewData'));
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
            if (!config) {
                Graph.isExpanding = false;
                return;
            }

            var payload = {
                ViewGroupID: 1,
                SourceNodeDataIDs: idsToExpand,
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

                    idsToExpand.forEach(function (idStr) {
                        var idInt = Interner.get(idStr);
                        var node = nodeMap.get(idInt);
                        if (node) {
                            var expandedIds = node.data('expandedIds') || [];
                            if (!expandedIds.includes(idInt)) {
                                expandedIds.push(idInt);
                                node.data('expandedIds', expandedIds);
                            }

                            var allIds = node.data('allIds');
                            if (allIds.length === expandedIds.length) {
                                // Optimization: Update Flag
                                var flags = node.data('flags') | FLAGS.EXPANDED;
                                node.data('flags', flags);
                                node.addClass('expanded');

                                var nodeIdInt = Interner.get(node.id());
                                Graph.expandableNodeIds.delete(nodeIdInt);
                            }
                        }
                    });

                    Graph.isExpanding = false;
                },
                error: function (err) {
                    console.error("Expansion failed", err);
                    alert(window.i18n.get('graph.expansionFailed'));
                    Graph.isExpanding = false;
                }
            });
        },

        clear: function () {
            Interner.clear();
            Graph.nodeLookup = new Map();
            Graph.internalIdLookup = new Map();
            Graph.idSets = new Map();
            Graph.svgCache = {};
            Graph.adjacencyList = new Map();
            Graph.expandableNodeIds = new Set();
            Graph.isExpanding = false;
            if (cy) cy.elements().remove();
        },

        setVisibleLegendIds: function (visibleIds) {
            if (!cy) return;

            var visibleSet = new Set(visibleIds.map(function (id) { return parseInt(id); }));

            cy.batch(function () {
                cy.nodes().forEach(function (node) {
                    var legendId = node.data('legendId');
                    // If legendId is 0 or undefined, we default to visible (or hidden? usually visible)
                    // Assuming all valid nodes have a legendId.
                    if (legendId && !visibleSet.has(legendId)) {
                        node.addClass('hidden');
                        // Hide connected edges too
                        node.connectedEdges().addClass('hidden');
                    } else {
                        node.removeClass('hidden');
                        // Show connected edges if both source and target are visible
                        node.connectedEdges().forEach(function (edge) {
                            var source = edge.source();
                            var target = edge.target();
                            if (!source.hasClass('hidden') && !target.hasClass('hidden')) {
                                edge.removeClass('hidden');
                            }
                        });
                    }
                });
            });
        },

        getSelectedNodes: function () {
            if (!cy) return [];
            return cy.nodes(':selected');
        },

        findShortestPath: function (sourceId, targetId) {
            if (!cy) return { found: false };

            var source = cy.getElementById(sourceId);
            var target = cy.getElementById(targetId);

            if (source.length === 0 || target.length === 0) return { found: false };

            var aStar = cy.elements().aStar({
                root: source,
                goal: target,
                directed: false // Allow undirected paths for better usability
            });

            if (aStar.found) {
                // Check for duplicates
                if (!Graph.paths) Graph.paths = new Map();

                var isDuplicate = false;
                var existingPathId = null;
                var existingColor = null;

                Graph.paths.forEach(function (path, id) {
                    var start = path[0];
                    var end = path[path.length - 1];
                    // Check if endpoints match (undirected)
                    if ((start.id() === sourceId && end.id() === targetId) ||
                        (start.id() === targetId && end.id() === sourceId)) {
                        isDuplicate = true;
                        existingPathId = id;
                        existingColor = path.data('pathColor');
                    }
                });

                if (isDuplicate) {
                    // Just ensure it's highlighted
                    var existingPath = Graph.paths.get(existingPathId);
                    existingPath.addClass('path-highlight');
                    return {
                        found: true,
                        id: existingPathId,
                        length: existingPath.length, // Note: this is element count, distance is better but not stored
                        color: existingColor,
                        isDuplicate: true
                    };
                }
                var pathId = Date.now(); // Simple ID
                // Store path in a map if needed for toggling, or just use class
                if (!Graph.paths) Graph.paths = new Map();
                Graph.paths.set(pathId, aStar.path);

                // Generate Distinct Color
                if (!Graph.pathColorIndex) Graph.pathColorIndex = 0;
                var colors = [
                    '#e6194b', '#3cb44b', '#ffe119', '#4363d8', '#f58231',
                    '#911eb4', '#46f0f0', '#f032e6', '#bcf60c', '#fabebe',
                    '#008080', '#e6beff', '#9a6324', '#fffac8', '#800000',
                    '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080',
                    '#ffffff', '#000000'
                ];
                var color = colors[Graph.pathColorIndex % colors.length];
                Graph.pathColorIndex++;

                // Assign color to path elements
                aStar.path.data('pathColor', color);

                // Highlight immediately
                aStar.path.addClass('path-highlight');

                return {
                    found: true,
                    id: pathId,
                    length: aStar.distance,
                    color: color
                };
            }

            return { found: false };
        },

        togglePath: function (pathId, visible) {
            if (!Graph.paths || !Graph.paths.has(pathId)) return;
            var path = Graph.paths.get(pathId);
            if (visible) {
                path.addClass('path-highlight');
            } else {
                path.removeClass('path-highlight');
            }
        },

        removePath: function (pathId) {
            if (!Graph.paths || !Graph.paths.has(pathId)) return;
            var path = Graph.paths.get(pathId);
            path.removeClass('path-highlight');
            Graph.paths.delete(pathId);
        }
    };

    window.Graph = Graph;

})();
