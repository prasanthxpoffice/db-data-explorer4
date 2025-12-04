(function () {
    'use strict';

    var Graph = window.Graph;

    // Create search nodes directly from search list
    Graph.createSearchNodes = function (searchNodes) {
        if (!Graph.cy || !searchNodes || searchNodes.length === 0) return;

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
            Graph.cy.add(nodesToAdd);

            var layoutName = $('#setting-layout').val() || 'cose';
            Graph.changeLayout(layoutName);

            Graph.updateStats();


            // Trigger auto-expand if enabled
            if (Graph.autoExpand) {
                setTimeout(function () {
                    Graph.expandNextBatch();
                }, 500);
            }
        }
    };

    // Expand nodes
    Graph.expandNodes = function (nodeIdentities) {
        if (!Graph.cy || Graph.isExpanding) return;

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



        var payload = {
            ViewGroupID: viewGroupId,
            SourceNodeIdentities: nodeIdentities,
            FilterNodes: filterNodes,
            MaxNeighbors: maxNeighbors,
            Lang: lang
        };



        $.ajax({
            url: config.api.nodesExpand.path,
            method: config.api.nodesExpand.method,
            contentType: 'application/json',
            data: JSON.stringify(payload),
            success: function (results) {


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
    };

    // Process expansion results
    Graph.processExpansionResults = function (results, sourceIdentities) {
        if (!results || results.length === 0) {
            // If no results, still mark source nodes as expanded so we don't try again immediately
            if (sourceIdentities) {
                sourceIdentities.forEach(function (identity) {
                    var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                    var node = Graph.cy.getElementById(nodeId);
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

        var nodesMap = new Map();
        var nodesToAdd = [];
        var edgesToAdd = [];

        // Helper to add node to map
        function addNodeToMap(groupNodeId, nodeValueId, nodeId, label, color) {
            var id = groupNodeId + '|' + nodeValueId;
            if (!nodesMap.has(id)) {
                nodesMap.set(id, {
                    label: label,
                    properties: []
                });
            }
            // Avoid duplicate properties for the same node in this batch
            var props = nodesMap.get(id).properties;
            var exists = props.some(p => p.NodeID === nodeId);
            if (!exists) {
                props.push({
                    NodeID: nodeId,
                    GroupNodeID: groupNodeId,
                    NodeValueID: nodeValueId,
                    NodeColor: color
                });
            }
        }

        // Collect all unique nodes (both source and target)
        results.forEach(function (item) {
            addNodeToMap(item.TargetGroupNodeID, item.TargetNodeValueID, item.TargetNodeID, item.TargetNodeValue, item.TargetNodeColor);
            addNodeToMap(item.SourceGroupNodeID, item.SourceNodeValueID, item.SourceNodeID, item.SourceNodeValue, item.SourceNodeColor);
        });

        Graph.cy.batch(function () {
            // Create/update nodes
            nodesMap.forEach(function (nodeData, nodeId) {
                var existingNode = Graph.cy.getElementById(nodeId);

                // Determine visibility based on legend
                var classes = '';
                if (Graph.visibleLegendIds) {
                    // Check if ANY of the aggregated NodeIDs are visible
                    var isVisible = nodeData.properties.some(function (p) {
                        return Graph.visibleLegendIds.has(String(p.NodeID));
                    });

                    if (!isVisible) {
                        classes = 'hidden-legend';
                    }
                }

                if (existingNode.length === 0) {
                    // Create new node
                    var colors = nodeData.properties.map(p => p.NodeColor);
                    // Filter unique colors
                    var uniqueColors = colors.filter(function (item, pos) {
                        return colors.indexOf(item) == pos;
                    });

                    var pieImage = Graph.createPieChart(uniqueColors);
                    var position = { x: Math.random() * 500, y: Math.random() * 500 };

                    var newNodeData = {
                        id: nodeId,
                        label: nodeData.label || 'Unknown',
                        color: uniqueColors[0],
                        properties: nodeData.properties,
                        isExpanded: false
                    };

                    if (pieImage) {
                        newNodeData.pieImage = pieImage;
                    }

                    nodesToAdd.push({
                        group: 'nodes',
                        classes: classes.trim(),
                        data: newNodeData,
                        position: position
                    });

                    Graph.unexpandedNodes.add(nodeId);
                    Graph.nodeSet.add(nodeId);
                } else {
                    // Update existing node - add new properties
                    var existingProps = existingNode.data('properties') || [];
                    var newPropsAdded = false;

                    nodeData.properties.forEach(function (newProp) {
                        if (!existingProps.some(p => p.NodeID === newProp.NodeID)) {
                            existingProps.push(newProp);
                            newPropsAdded = true;
                        }
                    });

                    if (newPropsAdded) {
                        existingNode.data('properties', existingProps);

                        // Update pie chart
                        var colors = existingProps.map(p => p.NodeColor);
                        var uniqueColors = colors.filter(function (item, pos) {
                            return colors.indexOf(item) == pos;
                        });

                        var pieImage = Graph.createPieChart(uniqueColors);
                        if (pieImage) {
                            existingNode.data('pieImage', pieImage);
                        }
                        existingNode.data('color', uniqueColors[0]);

                        // Update visibility if needed
                        if (Graph.visibleLegendIds) {
                            var isVisible = existingProps.some(function (p) {
                                return Graph.visibleLegendIds.has(String(p.NodeID));
                            });
                            if (isVisible) {
                                existingNode.removeClass('hidden-legend');
                            }
                        }
                    }
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
                if (Graph.cy.getElementById(edgeId).length > 0) return;

                // 3. Check if ANY edge exists between these two nodes in the graph
                // Only possible if both nodes are already in the graph
                var sourceNode = Graph.cy.getElementById(sourceId);
                var targetNode = Graph.cy.getElementById(targetId);

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
                Graph.edgeSet.add(pairKey);
            });

            // Add new elements
            if (nodesToAdd.length > 0) {
                Graph.cy.add(nodesToAdd);

            }

            if (edgesToAdd.length > 0) {
                Graph.cy.add(edgesToAdd);

            }

            // Mark source nodes as expanded
            if (sourceIdentities) {
                sourceIdentities.forEach(function (identity) {
                    var nodeId = identity.GroupNodeID + '|' + identity.NodeValueID;
                    var node = Graph.cy.getElementById(nodeId);
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
    };

    // Expand next batch
    Graph.expandNextBatch = function (batchSize) {
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
                var node = Graph.cy.getElementById(nodeId);
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
    };

    Graph.setAutoExpand = function (enabled) {
        Graph.autoExpand = enabled;
        if (enabled && Graph.unexpandedNodes.size > 0) {
            Graph.expandNextBatch();
        }
    };

    // Server-Side Path Finding
    Graph.findPathsServer = function (searchNodes) {
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
    };

})();
