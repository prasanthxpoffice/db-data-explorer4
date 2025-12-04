(function () {
    'use strict';

    var DEFAULT_NODE_COLOR = '#4A90E2';

    var Graph = {
        cy: null, // Cytoscape instance
        unexpandedNodes: new Set(),
        nodeSet: new Set(), // Persistent set of all node IDs
        edgeSet: new Set(), // Persistent set of all edge signatures (source|target)
        isExpanding: false,
        autoExpand: false,
        statusTimeout: null,
        visibleLegendIds: null, // Set of NodeIDs visible based on legend

        init: function (containerId) {
            Graph.cy = cytoscape({
                container: $(containerId),
                textureOnViewport: true,
                pixelRatio: 1,
                motionBlur: false,
                hideEdgesOnViewport: true,
                hideLabelsOnViewport: true,
                boxSelectionEnabled: false, // Disable box selection for performance
                minZoomedFontSize: 12, // Hide text sooner when zoomed out (increased from 12)
                style: [
                    {
                        selector: 'node',
                        style: {
                            'shape': 'round-rectangle',
                            'background-color': 'data(color)',
                            'label': 'data(label)',
                            'width': 'label',
                            'height': 'label',
                            'padding': '10px',
                            'font-size': 11,
                            'text-valign': 'center',
                            'text-halign': 'center',
                            'color': '#000',
                            'text-outline-width': 2,
                            'text-outline-color': '#fff',
                            'text-wrap': 'wrap',
                            'text-max-width': 100,
                            'text-overflow-wrap': 'anywhere'
                        }
                    },
                    {
                        selector: 'node[pieImage]',
                        style: {
                            'background-image': 'data(pieImage)',
                            'background-fit': 'cover'
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
                            'curve-style': 'bezier', // Bezier supports arrows
                            'label': 'data(label)',
                            'font-size': 8,
                            'text-rotation': 'autorotate',
                            'text-wrap': 'wrap',
                            'text-max-width': 100
                        }
                    },
                    {
                        selector: '.highlighted-path',
                        style: {
                            'z-index': 9999
                        }
                    },
                    {
                        selector: '.hidden-legend',
                        style: {
                            'display': 'none'
                        }
                    },
                    {
                        selector: '.hide-labels',
                        style: {
                            'text-opacity': 0,
                            'text-background-opacity': 0,
                            'text-border-opacity': 0
                        }
                    }
                ],
                layout: {
                    name: 'grid',
                    rows: 1
                }
            });




            // Event Listeners

            // Single Click (Tap) - Show Details
            Graph.cy.on('tap', 'node', function (evt) {
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
            Graph.cy.on('dbltap', 'node', function (evt) {
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
            Graph.cy.on('tap', function (evt) {
                if (evt.target === Graph.cy) {
                    $(document).trigger('nodeSelected', [null]);
                }
            });


            // Manual Level of Detail (LOD) - Hide labels when zoomed out
            var zoomTimeout;
            var toggleLOD = function () {
                var zoom = Graph.cy.zoom();
                // Threshold: Hide labels if zoom is less than 0.75 (75%)
                var showLabels = zoom >= 0.75;

                Graph.cy.batch(function () {
                    if (showLabels) {
                        Graph.cy.elements().removeClass('hide-labels');
                    } else {
                        Graph.cy.elements().addClass('hide-labels');
                    }
                });
            };

            Graph.cy.on('zoom', function () {
                if (zoomTimeout) clearTimeout(zoomTimeout);
                zoomTimeout = setTimeout(toggleLOD, 100); // Debounce 100ms
            });

            // Initial check
            toggleLOD();

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
            if (!Graph.cy) return;
            $('#stat-nodes').text(Graph.cy.nodes().length);
            $('#stat-edges').text(Graph.cy.edges().length);
            $('#stat-pending').text(Graph.unexpandedNodes.size);
        },

        clear: function () {
            if (Graph.cy) {
                Graph.cy.elements().remove();
                Graph.unexpandedNodes.clear();
                Graph.nodeSet.clear();
                Graph.edgeSet.clear();
                Graph.hiddenLeaves = null;
                Graph.updateStats();

            }
        },

        getSelectedNodes: function () {
            if (!Graph.cy) return [];
            return Graph.cy.nodes(':selected');
        },

        setVisibleLegendIds: function (selectedIds) {
            Graph.visibleLegendIds = new Set(selectedIds.map(String));

            if (!Graph.cy) return;

            Graph.cy.batch(function () {
                Graph.cy.nodes().forEach(function (node) {
                    var props = node.data('properties');
                    if (props && props.length > 0) {
                        // Check if ANY of the aggregated NodeIDs are visible
                        var visibleProps = props.filter(function (p) {
                            return Graph.visibleLegendIds.has(String(p.NodeID));
                        });

                        if (visibleProps.length > 0) {
                            node.removeClass('hidden-legend');

                            // Recalculate colors for visible properties
                            var visibleColors = visibleProps.map(function (p) { return p.NodeColor; });
                            var uniqueColors = visibleColors.filter(function (item, pos) {
                                return visibleColors.indexOf(item) == pos;
                            });

                            if (uniqueColors.length > 1) {
                                // Update pie chart with only visible colors
                                if (Graph.createPieChart) {
                                    var newPie = Graph.createPieChart(uniqueColors);
                                    node.data('pieImage', newPie);
                                }
                            } else {
                                // Single color or no pie needed
                                node.removeData('pieImage');
                                node.data('color', uniqueColors[0]);
                            }

                        } else {
                            node.addClass('hidden-legend');
                        }
                    }
                });
            });
        }
    };

    window.Graph = Graph;

})();
