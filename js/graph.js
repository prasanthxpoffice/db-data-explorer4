(function () {
    var cy = null;

    var Graph = {
        init: function (containerId) {
            console.log("Initializing Graph in", containerId);
            cy = cytoscape({
                container: $(containerId),
                style: [ // the stylesheet for the graph
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
                            'label': 'data(label)', // Show edge label
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

        addNodes: function (nodesData) {
            if (!cy) {
                console.error("Graph not initialized");
                return;
            }

            var nodesToAdd = [];
            nodesData.forEach(function (node) {
                // Cast ID to string to ensure consistency
                var nodeId = String(node.NodeDataID);

                // Check if node already exists to avoid duplicates
                if (cy.getElementById(nodeId).length === 0) {
                    nodesToAdd.push({
                        group: 'nodes',
                        data: {
                            id: nodeId,
                            label: node.NodeValue,
                            color: node.ColumnColor || '#666',
                            groupNodeId: node.GroupNodeID,
                            nodeValueId: node.NodeValueID,
                            nodeValueDate: node.NodeValueDate,
                            isExpanded: false // Default to false
                        }
                    });
                }
            });

            if (nodesToAdd.length > 0) {
                cy.add(nodesToAdd);
                cy.layout({ name: 'cose', animate: true }).run();
                console.log("Added " + nodesToAdd.length + " nodes to graph");
            } else {
                console.log("No new nodes to add");
            }
        },

        addExpansionResults: function (results) {
            if (!cy) return;

            console.log("Expansion Results (Raw):", results);
            if (results.length > 0) {
                console.log("Result Keys:", Object.keys(results[0]));
            }

            var nodesToAdd = [];
            var edgesToAdd = [];
            var sourceNodeIds = new Set();

            results.forEach(function (item) {
                // Ensure we handle case-sensitivity or missing columns
                // Actual keys from API: RelationDataID, SourceNodeDataID, TargetNodeDataID, Relation
                var sourceNodeID = item.SourceNodeDataID || item.SourceNodeID;
                var targetNodeID = item.TargetNodeDataID || item.TargetNodeID;
                var edgeID = item.RelationDataID || item.EdgeID;
                var edgeLabel = item.Relation || item.EdgeLabel;

                if (!sourceNodeID || !targetNodeID || !edgeID) {
                    console.warn("Missing ID in result item:", item);
                    return;
                }

                sourceNodeIds.add(sourceNodeID);

                var targetId = String(targetNodeID);
                var sourceId = String(sourceNodeID);
                var edgeId = String(edgeID);

                // Add Target Node if not exists
                if (cy.getElementById(targetId).length === 0) {
                    // Check if we already added it in this batch to avoid dupes in array
                    var alreadyInBatch = nodesToAdd.some(n => n.data.id === targetId);
                    if (!alreadyInBatch) {
                        nodesToAdd.push({
                            group: 'nodes',
                            data: {
                                id: targetId,
                                label: item.TargetNodeValue, // Mapped from TargetNodeValue
                                color: item.TargetNodeColor || '#666', // Mapped from TargetNodeColor
                                groupNodeId: item.TargetGroupNodeID,
                                nodeValueId: item.TargetNodeValueID,
                                nodeValueDate: item.TargetNodeValueDate, // Corrected from TargetNodeDate based on keys
                                isExpanded: false
                            }
                        });
                    }
                }

                // Add Edge if not exists
                if (cy.getElementById(edgeId).length === 0) {
                    var alreadyInBatch = edgesToAdd.some(e => e.data.id === edgeId);
                    if (!alreadyInBatch) {

                        // Check for existing connection in EITHER direction (A->B or B->A)
                        var existingEdge = cy.edges().filter(function (ele) {
                            return (ele.source().id() === sourceId && ele.target().id() === targetId) ||
                                (ele.source().id() === targetId && ele.target().id() === sourceId);
                        });

                        // Also check in current batch
                        var batchEdge = edgesToAdd.some(function (e) {
                            return (e.data.source === sourceId && e.data.target === targetId) ||
                                (e.data.source === targetId && e.data.target === sourceId);
                        });

                        if (existingEdge.length === 0 && !batchEdge) {
                            // Verify source exists
                            var sourceExists = cy.getElementById(sourceId).length > 0;
                            var sourceInBatch = nodesToAdd.some(n => n.data.id === sourceId);

                            if (!sourceExists && !sourceInBatch) {
                                console.error("CRITICAL: Source node NOT FOUND for edge:", edgeId, "SourceID:", sourceId);
                            }

                            edgesToAdd.push({
                                group: 'edges',
                                data: {
                                    id: edgeId,
                                    source: sourceId,
                                    target: targetId,
                                    label: edgeLabel
                                }
                            });
                        } else {
                            console.log("Skipping duplicate/reverse edge:", sourceId, "->", targetId);
                        }
                    }
                }
            });

            console.log("Adding Nodes:", nodesToAdd.length, "Edges:", edgesToAdd.length);

            if (nodesToAdd.length > 0) cy.add(nodesToAdd);

            // Add edges after nodes to ensure targets exist
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

            // Mark source nodes as expanded
            sourceNodeIds.forEach(function (id) {
                var node = cy.getElementById(String(id));
                if (node.length > 0) {
                    node.data('isExpanded', true);
                    node.style('border-width', 4); // Visual cue for expanded
                    node.style('border-color', '#333');
                }
            });
        },

        expandNextBatch: function () {
            if (!cy) return;

            // 1. Get Settings
            var batchSize = parseInt($('#setting-batch-size').val()) || 10;
            var maxNeighbors = parseInt($('#setting-max-neighbors').val()) || 5;

            // 2. Get Unexpanded Nodes
            var unexpanded = cy.nodes().filter(function (ele) {
                return ele.data('isExpanded') === false;
            });

            if (unexpanded.length === 0) {
                alert("No unexpanded nodes found.");
                return;
            }

            // Take batch
            var batch = unexpanded.slice(0, batchSize);
            var sourceIds = batch.map(function (ele) { return ele.id(); });

            // 3. Get Filters from Legends Grid
            var filters = [];
            var $grid = $('#legends-grid');
            if ($grid.length > 0) {
                var selectedRowIds = $grid.jqGrid('getGridParam', 'selarrrow');
                if (selectedRowIds) {
                    selectedRowIds.forEach(function (rowId) {
                        // Get Date Inputs
                        var $row = $grid.find('tr#' + rowId);
                        var fromDate = $row.find('.from-date').val(); // dd/mm/yyyy
                        var toDate = $row.find('.to-date').val();

                        // Convert to yyyy-mm-dd for API if needed, or let API handle it.
                        // Assuming API expects ISO or standard date. 
                        // Let's convert dd/mm/yyyy to yyyy-mm-dd
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

            // 4. Call API
            var config = window.parent.APP_CONFIG;
            if (!config) {
                console.error("APP_CONFIG not found");
                return;
            }

            var payload = {
                ViewGroupID: 1, // Default
                SourceNodeDataIDs: sourceIds,
                FilterNodes: filters,
                MaxNeighbors: maxNeighbors,
                Lang: config.Lang
            };

            // Get ViewGroupID from dropdown
            var viewGroupId = $('#view-groups-dropdown').val();
            if (viewGroupId) payload.ViewGroupID = parseInt(viewGroupId);

            $.ajax({
                url: config.api.nodesExpand.path,
                method: config.api.nodesExpand.method,
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function (data) {
                    Graph.addExpansionResults(data);

                    // Mark all source nodes as expanded, even if they returned no results
                    sourceIds.forEach(function (id) {
                        var node = cy.getElementById(String(id));
                        if (node.length > 0) {
                            node.data('isExpanded', true);
                            node.style('border-width', 4);
                            node.style('border-color', '#333');
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

    // Expose Graph globally
    window.Graph = Graph;

})();
