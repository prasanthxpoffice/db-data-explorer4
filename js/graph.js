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

        addNodes: function (nodesData) {
            if (!cy) return;

            var nodesToAdd = [];
            var addedIds = new Set();

            nodesData.forEach(function (node) {
                var nodeId = Graph.normalizeId(node.NodeDataID);

                if (!nodeId) return;

                if (cy.getElementById(nodeId).length === 0 && !addedIds.has(nodeId)) {
                    nodesToAdd.push({
                        group: 'nodes',
                        data: {
                            id: nodeId,
                            label: node.NodeValue,
                            color: node.ColumnColor || '#666',
                            groupNodeId: node.GroupNodeID,
                            nodeValueId: node.NodeValueID,
                            nodeValueDate: node.NodeValueDate,
                            isExpanded: false
                        }
                    });
                    addedIds.add(nodeId);
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
            var sourceNodeIds = new Set();

            var addedNodeIds = new Set();
            var addedEdgeIds = new Set();
            var addedEdgeConnections = new Set();

            results.forEach(function (item) {
                var sourceNodeID = item.SourceNodeDataID || item.SourceNodeID;
                var targetNodeID = item.TargetNodeDataID || item.TargetNodeID;
                var edgeID = item.RelationDataID || item.EdgeID;
                var edgeLabel = item.Relation || item.EdgeLabel;

                if (!sourceNodeID || !targetNodeID || !edgeID) return;

                sourceNodeIds.add(sourceNodeID);

                var targetId = Graph.normalizeId(targetNodeID);
                var sourceId = Graph.normalizeId(sourceNodeID);
                var edgeId = Graph.normalizeId(edgeID);

                if (cy.getElementById(targetId).length === 0) {
                    if (!addedNodeIds.has(targetId)) {
                        nodesToAdd.push({
                            group: 'nodes',
                            data: {
                                id: targetId,
                                label: item.TargetNodeValue,
                                color: item.TargetNodeColor || '#666',
                                groupNodeId: item.TargetGroupNodeID,
                                nodeValueId: item.TargetNodeValueID,
                                nodeValueDate: item.TargetNodeValueDate,
                                isExpanded: false
                            }
                        });
                        addedNodeIds.add(targetId);
                    }
                }

                if (cy.getElementById(edgeId).length === 0) {
                    if (!addedEdgeIds.has(edgeId)) {
                        var connectionKey1 = sourceId + "-" + targetId;
                        var connectionKey2 = targetId + "-" + sourceId;

                        if (!addedEdgeConnections.has(connectionKey1) && !addedEdgeConnections.has(connectionKey2)) {
                            var sourceNode = cy.getElementById(sourceId);
                            var existingEdge = false;

                            if (sourceNode.length > 0) {
                                var connected = sourceNode.connectedEdges();
                                existingEdge = connected.some(function (ele) {
                                    return (ele.source().id() === sourceId && ele.target().id() === targetId) ||
                                        (ele.source().id() === targetId && ele.target().id() === sourceId);
                                });
                            }

                            if (!existingEdge) {
                                edgesToAdd.push({
                                    group: 'edges',
                                    data: {
                                        id: edgeId,
                                        source: sourceId,
                                        target: targetId,
                                        label: edgeLabel
                                    }
                                });
                                addedEdgeIds.add(edgeId);
                                addedEdgeConnections.add(connectionKey1);
                                addedEdgeConnections.add(connectionKey2);
                            }
                        }
                    }
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

            sourceNodeIds.forEach(function (id) {
                var node = cy.getElementById(Graph.normalizeId(id));
                if (node.length > 0) {
                    node.data('isExpanded', true);
                }
            });
        },

        expandNextBatch: function () {
            if (!cy) return;

            var batchSize = parseInt($('#setting-batch-size').val()) || 50;
            var maxNeighbors = parseInt($('#setting-max-neighbors').val()) || 100;

            var unexpanded = cy.nodes().filter(function (ele) {
                return ele.data('isExpanded') === false;
            });

            if (unexpanded.length === 0) {
                alert("No unexpanded nodes found.");
                return;
            }

            var batch = unexpanded.slice(0, batchSize);
            var sourceIds = batch.map(function (ele) { return ele.id(); });

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
                SourceNodeDataIDs: sourceIds,
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

                    sourceIds.forEach(function (id) {
                        var node = cy.getElementById(Graph.normalizeId(id));
                        if (node.length > 0) {
                            node.data('isExpanded', true);
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
