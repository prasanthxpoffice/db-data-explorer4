// Fresh start: graph.js - Identity-based Graph Visualization with Property Arrays
// Using GroupNodeID + NodeValueID as the unique identifier for nodes

(function () {
    'use strict';

    var cy = null;
    var DEFAULT_NODE_COLOR = '#4A90E2';

    var Graph = {
        unexpandedNodes: new Set(),
        nodeSet: new Set(), // Persistent set of all node IDs
        edgeSet: new Set(), // Persistent set of all edge signatures (source|target)
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
                            'text-outline-color': '#fff',
                            'text-wrap': 'wrap',
                            'text-max-width': 45,
                            'text-overflow-wrap': 'anywhere'
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
                            'text-rotation': 'autorotate',
                            'text-wrap': 'wrap',
                            'text-max-width': 100
                        }
                    }
                ],
                layout: {
                    name: 'grid',
                    rows: 1
                }
            });


            console.log('Graph initialized');

            // Event Listeners

            // Single Click (Tap) - Show Details
            cy.on('tap', 'node', function (evt) {
                var node = evt.target;
                var props = node.data('properties');
                var nodeData = {
                    id: node.id(),
                    type: props && props.length > 0 ? props[0].GroupNodeID : 'Unknown',
                    label: node.data('label'),
                    connectedNodes: []
                };

                // Get connected nodes
                node.connectedEdges().forEach(function (edge) {
                    var connectedNode = edge.source().id() === node.id() ? edge.target() : edge.source();
                    nodeData.connectedNodes.push({
                        nodeId: connectedNode.id(),
                        nodeLabel: connectedNode.data('label'),
                        relationship: edge.data('label')
                    });
                });

                $(document).trigger('nodeSelected', [nodeData]);

                // Open Entity Info panel
                // $("#main-accordion").accordion("option", "active", 4); // Index 4 is Entity Info
            });

            // Double Click (Double Tap) - Expand
            cy.on('dbltap', 'node', function (evt) {
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

            // Background Click - Deselect
            cy.on('tap', function (evt) {
                if (evt.target === cy) {
                    $(document).trigger('nodeSelected', [null]);
                }
            });

            console.log('Graph initialized with event listeners');
        },

        showLoading: function () {
            var $loader = $('#graph-loader');
            if ($loader.length === 0) {
                $('body').append('<div id="graph-loader" style="position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(255,255,255,0.8);z-index:9999;display:flex;justify-content:center;align-items:center;font-size:24px;color:#333;">Loading...</div>');
                $loader = $('#graph-loader');
            }
            $loader.show();
        },

        hideLoading: function () {
            $('#graph-loader').hide();
        },

        // Cache for pie chart SVGs
        pieChartCache: {},

        // Create pie chart SVG for multi-color nodes
        createPieChart: function (colors) {
            if (!colors || colors.length === 0) return null;
            if (colors.length === 1) return null; // Single color, no pie needed

            // Sort colors to ensure consistent key
            var colorKey = colors.slice().sort().join(',');
            if (Graph.pieChartCache[colorKey]) {
                return Graph.pieChartCache[colorKey];
            }

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

            var result = 'data:image/svg+xml;base64,' + btoa(svg);
            Graph.pieChartCache[colorKey] = result;
            return result;
        },

        // Create search nodes directly from search list
        createSearchNodes: function (searchNodes) {
            if (!cy || !searchNodes || searchNodes.length === 0) return;

            var nodesToAdd = [];

            searchNodes.forEach(function (node) {
                var nodeId = node.GroupNodeID + '|' + node.NodeValueID;

                // Check if node already exists (using fast lookup)
                if (Graph.nodeSet.has(nodeId)) {
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
                Graph.nodeSet.add(nodeId);
            });

            if (nodesToAdd.length > 0) {
                cy.add(nodesToAdd);

                var layoutName = $('#setting-layout').val() || 'cose';
                Graph.changeLayout(layoutName);

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

                    if (Graph.autoExpand) {
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
                if (sourceIdentities) {
                    sourceIdentities.forEach(function (identity) {
                        var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                        var node = cy.getElementById(nodeId);
                        if (node.length > 0) {
                            node.data('isExpanded', true);
                            node.addClass('expanded');
                            Graph.unexpandedNodes.delete(nodeId);
                        }
                    });
                }
                Graph.updateStats();
                return;
            }

            var nodesToAdd = [];
            var edgesToAdd = [];
            var processedNodes = new Set(); // Track nodes processed in this batch to avoid duplicates
            var processedEdges = new Set(); // Track edges processed in this batch

            cy.batch(function () {
                results.forEach(function (item) {
                    // Process Target Node
                    var targetId = item.TargetGroupNodeID + '|' + item.TargetNodeValueID;
                    if (!Graph.nodeSet.has(targetId) && !processedNodes.has(targetId)) {
                        var colors = [item.TargetNodeColor]; // Assuming single color for now from API
                        var pieImage = null; // Optimization: Skip pie chart for single color

                        // Initial position optimization
                        var position = { x: Math.random() * 500, y: Math.random() * 500 };

                        nodesToAdd.push({
                            group: 'nodes',
                            data: {
                                id: targetId,
                                label: item.TargetNodeValue || 'Unknown',
                                color: item.TargetNodeColor,
                                pieImage: pieImage,
                                properties: [{
                                    NodeID: item.TargetNodeID,
                                    GroupNodeID: item.TargetGroupNodeID,
                                    NodeValueID: item.TargetNodeValueID,
                                    NodeColor: item.TargetNodeColor
                                }],
                                isExpanded: false
                            },
                            position: position
                        });
                        processedNodes.add(targetId);
                        Graph.nodeSet.add(targetId);
                        Graph.unexpandedNodes.add(targetId);
                    }

                    // Process Source Node (if not exists)
                    var sourceId = item.SourceGroupNodeID + '|' + item.SourceNodeValueID;
                    if (!Graph.nodeSet.has(sourceId) && !processedNodes.has(sourceId)) {
                        var position = { x: Math.random() * 500, y: Math.random() * 500 };
                        nodesToAdd.push({
                            group: 'nodes',
                            data: {
                                id: sourceId,
                                label: item.SourceNodeValue || 'Unknown',
                                color: item.SourceNodeColor,
                                pieImage: null,
                                properties: [{
                                    NodeID: item.SourceNodeID,
                                    GroupNodeID: item.SourceGroupNodeID,
                                    NodeValueID: item.SourceNodeValueID,
                                    NodeColor: item.SourceNodeColor
                                }],
                                isExpanded: false
                            },
                            position: position
                        });
                        processedNodes.add(sourceId);
                        Graph.nodeSet.add(sourceId);
                        Graph.unexpandedNodes.add(sourceId);
                    }

                    // Process Edge
                    var edgeId = 'e' + item.RelationDataID;
                    var pairKey = [sourceId, targetId].sort().join('|');

                    if (!Graph.edgeSet.has(pairKey) && !processedEdges.has(pairKey)) {
                        edgesToAdd.push({
                            group: 'edges',
                            data: {
                                id: edgeId,
                                source: sourceId,
                                target: targetId,
                                label: item.Relation || ''
                            }
                        });
                        processedEdges.add(pairKey);
                        Graph.edgeSet.add(pairKey);
                    }
                });

                // Add new elements
                if (nodesToAdd.length > 0) {
                    cy.add(nodesToAdd);
                    console.log('Added ' + nodesToAdd.length + ' nodes');
                }

                if (edgesToAdd.length > 0) {
                    cy.add(edgesToAdd);
                    console.log('Added ' + edgesToAdd.length + ' edges');
                }

                // Mark source nodes as expanded
                if (sourceIdentities) {
                    sourceIdentities.forEach(function (identity) {
                        var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                        var node = cy.getElementById(nodeId);
                        if (node.length > 0) {
                            node.data('isExpanded', true);
                            node.addClass('expanded');
                            Graph.unexpandedNodes.delete(nodeId);
                        }
                    });
                }
            });

            // Run layout
            if (nodesToAdd.length > 0 || edgesToAdd.length > 0) {
                var layoutName = $('#setting-layout').val() || 'cose';
                Graph.changeLayout(layoutName);
            }

            Graph.updateStats();
        },


        // Expand next batch
        expandNextBatch: function (batchSize) {
            if (Graph.isExpanding) return;

            if (Graph.unexpandedNodes.size === 0) {
                Graph.showStatus(window.i18n.get('graph.allExpanded', 'All nodes expanded'), 'success');
                return;
            }

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

        statusTimeout: null,

        showStatus: function (message, type, duration) {
            var $notification = $('#status-notification');
            $notification.removeClass('error success info').addClass(type || 'info').text(message).addClass('show');

            if (Graph.statusTimeout) {
                clearTimeout(Graph.statusTimeout);
            }

            if (duration !== 0) {
                Graph.statusTimeout = setTimeout(function () {
                    $notification.removeClass('show');
                }, duration || 3000);
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
                    layoutConfig.randomize = false; // Use existing/initial positions
                    layoutConfig.nodeRepulsion = 400000;
                    layoutConfig.idealEdgeLength = 100;
                    layoutConfig.edgeElasticity = 100;
                    layoutConfig.nestingFactor = 5;
                    layoutConfig.gravity = 80;
                    layoutConfig.numIter = 500; // Reduced from 1000 for speed
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

        // Server-Side Path Finding
        findPathsServer: function (searchNodes) {
            if (!searchNodes || searchNodes.length < 2) return;

            var config = window.parent.APP_CONFIG;
            if (!config || !config.api || !config.api.nodesFindPath) {
                console.error("API config missing: nodesFindPath");
                return;
            }

            // Construct payload
            var sourceIdentities = searchNodes.map(function (node) {
                return {
                    GroupNodeID: node.GroupNodeID,
                    NodeValueID: node.NodeValueID
                };
            });

            var maxDepth = parseInt($('#setting-max-depth').val()) || 4;

            var payload = {
                ViewGroupID: config.viewGroupId || 1,
                SourceNodeIdentities: sourceIdentities,
                MaxDepth: maxDepth,
                Lang: window.i18n ? window.i18n.currentLang : 'en-US'
            };

            var url = config.api.nodesFindPath.path;

            Graph.showLoading();

            $.ajax({
                url: url,
                method: 'POST',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function (results) {
                    console.log('Path Finding Results:', results);

                    if (results && results.error) {
                        console.error("Server error:", results.error);
                        Graph.showStatus("Server Error: " + results.error, 'error');
                        Graph.hideLoading();
                        return;
                    }

                    if (!results || results.length === 0) {
                        Graph.showStatus(window.i18n.get('path.notFound', 'No paths found between selected nodes within depth limit.'), 'info');
                        Graph.hideLoading();
                        return;
                    }

                    Graph.processExpansionResults(results, sourceIdentities);

                    // Run layout
                    var layoutName = $('#setting-layout').val() || 'cose';
                    Graph.changeLayout(layoutName);

                    Graph.hideLoading();
                },
                error: function (xhr, status, error) {
                    console.error("Path finding error:", error);
                    Graph.showStatus(window.i18n.get('app.errorLoading', 'Error loading data'), 'error');
                    Graph.hideLoading();
                }
            });
        },

        // Client-Side Path Finding (existing)
        paths: {},
        pathColors: ['#ff0000', '#00ff00', '#0000ff', '#ff00ff', '#00ffff', '#ffa500'],
        pathColorIndex: 0,

        findShortestPath: function (sourceId, targetId) {
            if (!cy) return { found: false };

            var source = cy.getElementById(sourceId);
            var target = cy.getElementById(targetId);

            if (source.length === 0 || target.length === 0) {
                return { found: false };
            }

            // Check if path already exists
            var existingPathId = null;
            Object.keys(Graph.paths).forEach(function (id) {
                var p = Graph.paths[id];
                if ((p.sourceId === sourceId && p.targetId === targetId) ||
                    (p.sourceId === targetId && p.targetId === sourceId)) {
                    existingPathId = id;
                }
            });

            if (existingPathId) {
                // Highlight existing
                Graph.togglePath(existingPathId, true);
                return { found: true, isDuplicate: true, id: existingPathId };
            }

            // Use Cytoscape's A* algorithm (good for shortest path)
            var aStar = cy.elements().aStar({
                root: source,
                goal: target,
                directed: false // Treat as undirected for now
            });

            if (aStar.found) {
                var pathId = 'path-' + new Date().getTime();
                var color = Graph.pathColors[Graph.pathColorIndex % Graph.pathColors.length];
                Graph.pathColorIndex++;

                // Store path details
                Graph.paths[pathId] = {
                    id: pathId,
                    sourceId: sourceId,
                    targetId: targetId,
                    elements: aStar.path,
                    color: color,
                    visible: true
                };

                // Highlight path
                aStar.path.addClass('highlighted-path');
                aStar.path.style('line-color', color);
                aStar.path.style('target-arrow-color', color);
                aStar.path.style('border-color', color);
                aStar.path.style('border-width', 4);
                aStar.path.edges().style('width', 4);

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
            var path = Graph.paths[pathId];
            if (path) {
                path.visible = visible;
                if (visible) {
                    path.elements.style('line-color', path.color);
                    path.elements.style('target-arrow-color', path.color);
                    path.elements.style('border-color', path.color);
                    path.elements.style('width', 4);
                    path.elements.edges().style('width', 4);
                } else {
                    path.elements.removeStyle('line-color');
                    path.elements.removeStyle('target-arrow-color');
                    path.elements.removeStyle('border-color');
                    path.elements.removeStyle('width');
                    path.elements.edges().removeStyle('width');
                }
            }
        },

        removePath: function (pathId) {
            var path = Graph.paths[pathId];
            if (path) {
                path.elements.removeStyle('line-color');
                path.elements.removeStyle('target-arrow-color');
                path.elements.removeStyle('border-color');
                path.elements.removeStyle('width');
                path.elements.edges().removeStyle('width');
                path.elements.removeClass('highlighted-path');
                delete Graph.paths[pathId];
            }
        },

        getSelectedNodes: function () {
            if (!cy) return [];
            return cy.nodes(':selected');
        },

        hiddenLeaves: null,

        toggleLeaves: function (shouldHide) {
            if (!cy) return;

            if (shouldHide) {
                // Hide leaves
                var leaves = cy.nodes().filter(function (ele) {
                    return ele.degree() <= 1;
                });

                if (leaves.length > 0) {
                    // Update persistent set before removing
                    leaves.forEach(function (node) {
                        Graph.nodeSet.delete(node.id());
                        // Also remove connected edges from edgeSet
                        node.connectedEdges().forEach(function (edge) {
                            var src = edge.data('source');
                            var tgt = edge.data('target');
                            var pairKey = [src, tgt].sort().join('|');
                            Graph.edgeSet.delete(pairKey);
                        });
                    });

                    Graph.hiddenLeaves = leaves.remove();
                    var count = Graph.hiddenLeaves.length;
                    Graph.updateStats();
                    var msg = (window.i18n ? window.i18n.get('graph.leavesHidden') : 'Hidden {0} leaf nodes').replace('{0}', count);
                    Graph.showStatus(msg, 'success');
                } else {
                    Graph.showStatus(window.i18n ? window.i18n.get('graph.noLeaves') : "No leaf nodes found to hide.", 'info');
                }
            } else {
                // Show leaves
                if (Graph.hiddenLeaves) {
                    // Update persistent set before restoring
                    Graph.hiddenLeaves.forEach(function (node) {
                        Graph.nodeSet.add(node.id());
                        // Edges are restored with the node, so add them back to edgeSet
                        node.connectedEdges().forEach(function (edge) {
                            var src = edge.data('source');
                            var tgt = edge.data('target');
                            var pairKey = [src, tgt].sort().join('|');
                            Graph.edgeSet.add(pairKey);
                        });
                    });

                    Graph.hiddenLeaves.restore();
                    var count = Graph.hiddenLeaves.length;
                    Graph.hiddenLeaves = null;
                    Graph.updateStats();
                    var msg = (window.i18n ? window.i18n.get('graph.leavesRestored') : 'Restored {0} leaf nodes').replace('{0}', count);
                    Graph.showStatus(msg, 'success');
                }
            }
        },

        saveAsImage: function () {
            if (!cy) return;
            var png64 = cy.png({ full: true, scale: 2, bg: 'white' });
            var link = document.createElement('a');
            link.download = 'graph-view-' + new Date().getTime() + '.png';
            link.href = png64;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        },

        clear: function () {
            if (cy) {
                cy.elements().remove();
                Graph.unexpandedNodes.clear();
                Graph.nodeSet.clear();
                Graph.edgeSet.clear();
                Graph.hiddenLeaves = null;
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
