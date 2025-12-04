// Fresh start: graph.js - Identity-based Graph Visualization with Property Arrays
// Using GroupNodeID + NodeValueID as the unique identifier for nodes

(function () {
    'use strict';

    var cy = null;
    var DEFAULT_NODE_COLOR = '#4A90E2';

    var Graph = {
        unexpandedNodes: new Set(),
        isExpanding: false,
        autoExpand: false,

        init: function (containerId) {
            cy = cytoscape({
                container: $(containerId),
                style: [
                    {
                        selector: 'node',
                        style: {
                            'background-color': 'data(color)',
                            'background-image': 'data(pieImage)',
                            'background-fit': 'cover',
                            'label': 'data(label)',
                            'width': 50,
                            'height': 50,
                            'font-size': 10,
                            'text-valign': 'center',
                            'text-halign': 'center',
                            'color': '#000',
                            'text-outline-width': 2,
                            'text-outline-color': '#fff'
                        }
                    },
                    {
                        selector: 'node.expanded',
                        style: {
                            'border-width': 3,
                            'border-color': '#28a745'
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
                            'font-size': 8,
                            'text-rotation': 'autorotate'
                        }
                    }
                ],
                layout: {
                    name: 'grid',
                    rows: 1
                }
            });

            console.log('Graph initialized');
        },

        // Create pie chart SVG for multi-color nodes
        createPieChart: function (colors) {
            if (!colors || colors.length === 0) return null;
            if (colors.length === 1) return null; // Single color, no pie needed

            var size = 100;
            var radius = 50;
            var cx = 50;
            var cy = 50;

            var total = colors.length;
            var anglePerSlice = 360 / total;
            var currentAngle = 0;

            var paths = [];
            colors.forEach(function (color) {
                var startAngle = currentAngle;
                var endAngle = currentAngle + anglePerSlice;

                var x1 = cx + radius * Math.cos((startAngle - 90) * Math.PI / 180);
                var y1 = cy + radius * Math.sin((startAngle - 90) * Math.PI / 180);
                var x2 = cx + radius * Math.cos((endAngle - 90) * Math.PI / 180);
                var y2 = cy + radius * Math.sin((endAngle - 90) * Math.PI / 180);

                var largeArc = anglePerSlice > 180 ? 1 : 0;

                var pathData = [
                    'M', cx, cy,
                    'L', x1, y1,
                    'A', radius, radius, 0, largeArc, 1, x2, y2,
                    'Z'
                ].join(' ');

                paths.push('<path d="' + pathData + '" fill="' + color + '"/>');
                currentAngle = endAngle;
            });

            var svg = '<svg width="' + size + '" height="' + size + '" xmlns="http://www.w3.org/2000/svg">' +
                paths.join('') +
                '</svg>';

            return 'data:image/svg+xml;base64,' + btoa(svg);
        },

        // Create search nodes directly from search list
        createSearchNodes: function (searchNodes) {
            if (!cy || !searchNodes || searchNodes.length === 0) return;

            var nodesToAdd = [];

            searchNodes.forEach(function (node) {
                var nodeId = node.GroupNodeID + '|' + node.NodeValueID;

                // Check if node already exists
                if (cy.getElementById(nodeId).length > 0) {
                    return;
                }

                // Create initial property object
                var initialProperty = {
                    NodeID: node.NodeID,
                    GroupNodeID: node.GroupNodeID,
                    NodeValueID: node.NodeValueID,
                    NodeColor: node.NodeColor
                };

                nodesToAdd.push({
                    group: 'nodes',
                    data: {
                        id: nodeId,
                        label: node.NodeValue || 'Unknown',
                        color: node.NodeColor,
                        properties: [initialProperty], // Array of property objects
                        isExpanded: false
                    }
                });

                Graph.unexpandedNodes.add(nodeId);
            });

            if (nodesToAdd.length > 0) {
                cy.add(nodesToAdd);

                cy.layout({
                    name: 'cose',
                    animate: true,
                    animationDuration: 500
                }).run();

                Graph.updateStats();
                console.log('Created ' + nodesToAdd.length + ' search nodes');

                // Trigger auto-expand if enabled
                if (Graph.autoExpand) {
                    setTimeout(function () {
                        Graph.expandNextBatch();
                    }, 500);
                }
            }
        },

        // Expand nodes
        expandNodes: function (nodeIdentities) {
            if (!cy || Graph.isExpanding) return;

            Graph.isExpanding = true;

            var config = window.parent.APP_CONFIG;
            if (!config) {
                console.error('APP_CONFIG not found');
                Graph.isExpanding = false;
                return;
            }

            var lang = window.i18n ? window.i18n.currentLang : 'en-US';

            // Get ViewGroupID from global state
            var viewGroupId = window.currentViewGroupId || 1;

            // Get MaxNeighbors from settings
            var maxNeighbors = Graph.maxNeighbors || parseInt($('#setting-max-neighbors').val()) || 100;

            // Get filter nodes from legends grid (includes user-modified dates)
            var filterNodes = [];
            var $legendsGrid = $('#legends-grid');
            if ($legendsGrid.length > 0) {
                var selectedRowIds = $legendsGrid.jqGrid('getGridParam', 'selarrrow');
                if (selectedRowIds && selectedRowIds.length > 0) {
                    selectedRowIds.forEach(function (rowId) {
                        var $row = $('#' + rowId);
                        var nodeId = parseInt(rowId);

                        // Check if date filter is enabled
                        var $dateSwitch = $row.find('.switch input');
                        var isDateFilterEnabled = $dateSwitch.is(':checked');

                        var fromDate = new Date('1900-01-01');
                        var toDate = new Date('2099-12-31');

                        if (isDateFilterEnabled) {
                            var $fromInput = $row.find('.from-date');
                            var $toInput = $row.find('.to-date');

                            if ($fromInput.val()) {
                                fromDate = $fromInput.datepicker('getDate') || fromDate;
                            }
                            if ($toInput.val()) {
                                toDate = $toInput.datepicker('getDate') || toDate;
                            }
                        }

                        filterNodes.push({
                            NodeID: nodeId,
                            FromDate: fromDate,
                            ToDate: toDate
                        });
                    });
                }
            }

            console.log('Expanding nodes:', nodeIdentities);
            console.log('ViewGroupID:', viewGroupId, 'MaxNeighbors:', maxNeighbors);
            console.log('Filter nodes from legends grid:', filterNodes.length, 'nodes');

            var payload = {
                ViewGroupID: viewGroupId,
                SourceNodeIdentities: nodeIdentities,
                FilterNodes: filterNodes,
                MaxNeighbors: maxNeighbors,
                Lang: lang
            };

            console.log('=== PAYLOAD BEING SENT ===');
            console.log('Full payload:', JSON.stringify(payload, null, 2));
            console.log('==========================');

            $.ajax({
                url: config.api.nodesExpand.path,
                method: config.api.nodesExpand.method,
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function (results) {
                    console.log('=== EXPANSION RESULTS DEBUG ===');
                    console.log('Results:', results);
                    console.log('Type:', typeof results);
                    console.log('Is Array:', Array.isArray(results));
                    console.log('Length:', results ? results.length : 'null/undefined');
                    if (results && results.length > 0) {
                        console.log('First item:', results[0]);
                        console.log('First item keys:', Object.keys(results[0]));
                    }
                    console.log('===============================');

                    Graph.processExpansionResults(results, nodeIdentities);
                    Graph.isExpanding = false;

                    if (Graph.autoExpand && Graph.unexpandedNodes.size > 0) {
                        setTimeout(function () {
                            Graph.expandNextBatch();
                        }, 500);
                    }
                },
                error: function (xhr, status, error) {
                    console.error('Error expanding nodes:', error, xhr.responseText);
                    Graph.isExpanding = false;
                }
            });
        },

        // Process expansion results
        processExpansionResults: function (results, sourceIdentities) {
            if (!results || results.length === 0) {
                sourceIdentities.forEach(function (identity) {
                    var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                    var node = cy.getElementById(nodeId);
                    if (node.length > 0) {
                        node.data('isExpanded', true);
                        node.addClass('expanded');
                        Graph.unexpandedNodes.delete(nodeId);
                    }
                });
                Graph.updateStats();
                return;
            }

            var targetNodesMap = new Map();
            var nodesToAdd = [];
            var edgesToAdd = [];

            // Collect unique target nodes
            results.forEach(function (item) {
                var targetId = item.TargetGroupNodeID + '|' + item.TargetNodeValueID;

                if (!targetNodesMap.has(targetId)) {
                    targetNodesMap.set(targetId, {
                        label: item.TargetNodeValue,
                        properties: []
                    });
                }

                // Add target property
                targetNodesMap.get(targetId).properties.push({
                    NodeID: item.TargetNodeID,
                    GroupNodeID: item.TargetGroupNodeID,
                    NodeValueID: item.TargetNodeValueID,
                    NodeColor: item.TargetNodeColor
                });
            });

            cy.batch(function () {
                // Create/update target nodes
                targetNodesMap.forEach(function (nodeData, targetId) {
                    var existingNode = cy.getElementById(targetId);

                    if (existingNode.length === 0) {
                        // Create new target node
                        var colors = nodeData.properties.map(p => p.NodeColor);
                        var pieImage = Graph.createPieChart(colors);

                        nodesToAdd.push({
                            group: 'nodes',
                            data: {
                                id: targetId,
                                label: nodeData.label || 'Unknown',
                                color: colors[0],
                                pieImage: pieImage,
                                properties: nodeData.properties,
                                isExpanded: false
                            }
                        });

                        Graph.unexpandedNodes.add(targetId);
                    } else {
                        // Update existing node - add new properties
                        var existingProps = existingNode.data('properties') || [];
                        nodeData.properties.forEach(function (newProp) {
                            existingProps.push(newProp);
                        });

                        existingNode.data('properties', existingProps);

                        // Update pie chart
                        var colors = existingProps.map(p => p.NodeColor);
                        var pieImage = Graph.createPieChart(colors);
                        existingNode.data('pieImage', pieImage);
                        existingNode.data('color', colors[0]);
                    }
                });

                // Update source node properties
                results.forEach(function (item) {
                    var sourceId = item.SourceGroupNodeID + '|' + item.SourceNodeValueID;
                    var sourceNode = cy.getElementById(sourceId);

                    if (sourceNode.length > 0) {
                        var sourceProps = sourceNode.data('properties') || [];

                        // Add source property
                        sourceProps.push({
                            NodeID: item.SourceNodeID,
                            GroupNodeID: item.SourceGroupNodeID,
                            NodeValueID: item.SourceNodeValueID,
                            NodeColor: item.SourceNodeColor
                        });

                        sourceNode.data('properties', sourceProps);

                        // Update pie chart
                        var colors = sourceProps.map(p => p.NodeColor);
                        var pieImage = Graph.createPieChart(colors);
                        sourceNode.data('pieImage', pieImage);
                        sourceNode.data('color', colors[0]);
                    }
                });

                // Create edges
                var processedPairs = new Set();

                results.forEach(function (item) {
                    var sourceId = item.SourceGroupNodeID + '|' + item.SourceNodeValueID;
                    var targetId = item.TargetGroupNodeID + '|' + item.TargetNodeValueID;
                    var edgeId = 'e' + item.RelationDataID;

                    // Create a unique key for the pair (sorted to be direction-agnostic)
                    var pairKey = [sourceId, targetId].sort().join('|');

                    // 1. Check if we already processed this pair in this batch
                    if (processedPairs.has(pairKey)) return;

                    // 2. Check if edge already exists in graph (by ID)
                    if (cy.getElementById(edgeId).length > 0) return;

                    // 3. Check if ANY edge exists between these two nodes in the graph
                    // Only possible if both nodes are already in the graph
                    var sourceNode = cy.getElementById(sourceId);
                    var targetNode = cy.getElementById(targetId);

                    if (sourceNode.length > 0 && targetNode.length > 0) {
                        // edgesWith returns edges in either direction
                        if (sourceNode.edgesWith(targetNode).length > 0) return;
                    }

                    edgesToAdd.push({
                        group: 'edges',
                        data: {
                            id: edgeId,
                            source: sourceId,
                            target: targetId,
                            label: item.Relation || ''
                        }
                    });

                    processedPairs.add(pairKey);
                });

                // Add new elements
                if (nodesToAdd.length > 0) {
                    cy.add(nodesToAdd);
                    console.log('Added ' + nodesToAdd.length + ' target nodes');
                }

                if (edgesToAdd.length > 0) {
                    cy.add(edgesToAdd);
                    console.log('Added ' + edgesToAdd.length + ' edges');
                }

                // Mark source nodes as expanded
                sourceIdentities.forEach(function (identity) {
                    var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                    var node = cy.getElementById(nodeId);
                    if (node.length > 0) {
                        node.data('isExpanded', true);
                        node.addClass('expanded');
                        Graph.unexpandedNodes.delete(nodeId);
                    }
                });
            });

            // Run layout
            // Run layout
            if (nodesToAdd.length > 0 || edgesToAdd.length > 0) {
                var layoutName = $('#setting-layout').val() || 'cose';
                Graph.changeLayout(layoutName);
            }

            Graph.updateStats();
        },

        // Expand next batch
        expandNextBatch: function (batchSize) {
            if (Graph.isExpanding || Graph.unexpandedNodes.size === 0) return;

            batchSize = batchSize || 10;
            var batch = [];
            var count = 0;

            Graph.unexpandedNodes.forEach(function (nodeId) {
                if (count < batchSize) {
                    var node = cy.getElementById(nodeId);
                    if (node.length > 0) {
                        var props = node.data('properties');
                        if (props && props.length > 0) {
                            batch.push({
                                GroupNodeID: props[0].GroupNodeID,
                                NodeValueID: props[0].NodeValueID
                            });
                            count++;
                        }
                    }
                }
            });

            if (batch.length > 0) {
                Graph.expandNodes(batch);
            }
        },

        setAutoExpand: function (enabled) {
            Graph.autoExpand = enabled;
            if (enabled && Graph.unexpandedNodes.size > 0) {
                Graph.expandNextBatch();
            }
        },

        updateStats: function () {
            if (!cy) return;
            $('#stat-nodes').text(cy.nodes().length);
            $('#stat-edges').text(cy.edges().length);
            $('#stat-pending').text(Graph.unexpandedNodes.size);
        },

        changeLayout: function (layoutName) {
            if (!cy) return;

            var layoutConfig = {
                name: layoutName,
                animate: true,
                animationDuration: 500,
                padding: 30
            };

            switch (layoutName) {
                case 'cose':
                    layoutConfig.nodeRepulsion = 400000;
                    layoutConfig.idealEdgeLength = 100;
                    layoutConfig.edgeElasticity = 100;
                    layoutConfig.nestingFactor = 5;
                    layoutConfig.gravity = 80;
                    layoutConfig.numIter = 1000;
                    layoutConfig.initialTemp = 200;
                    layoutConfig.coolingFactor = 0.95;
                    layoutConfig.minTemp = 1.0;
                    break;
                case 'concentric':
                    layoutConfig.minNodeSpacing = 50;
                    layoutConfig.levelWidth = function (nodes) { return 2; };
                    break;
                case 'breadthfirst':
                    layoutConfig.directed = true;
                    layoutConfig.spacingFactor = 1.75;
                    break;
                case 'grid':
                    layoutConfig.avoidOverlap = true;
                    break;
                case 'circle':
                    layoutConfig.avoidOverlap = true;
                    layoutConfig.radius = null;
                    break;
            }

            var layout = cy.layout(layoutConfig);
            layout.run();
            console.log('Layout changed to:', layoutName);
        },

        clear: function () {
            if (cy) {
                cy.elements().remove();
                Graph.unexpandedNodes.clear();
                Graph.updateStats();
                console.log('Graph cleared');
            }
        }
    };

    window.Graph = Graph;

    // Double-click to expand
    $(document).ready(function () {
        if (cy) {
            cy.on('dblclick', 'node', function (evt) {
                var node = evt.target;
                if (!node.data('isExpanded')) {
                    var props = node.data('properties');
                    if (props && props.length > 0) {
                        Graph.expandNodes([{
                            GroupNodeID: props[0].GroupNodeID,
                            NodeValueID: props[0].NodeValueID
                        }]);
                    }
                }
            });
        }
    });

})();
