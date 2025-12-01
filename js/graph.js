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
                            'curve-style': 'bezier'
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
                // Check if node already exists to avoid duplicates
                if (cy.getElementById(node.NodeDataID).length === 0) {
                    nodesToAdd.push({
                        group: 'nodes',
                        data: {
                            id: node.NodeDataID,
                            label: node.NodeValue,
                            color: node.ColumnColor || '#666',
                            groupNodeId: node.GroupNodeID,
                            nodeValueId: node.NodeValueID,
                            nodeValueDate: node.NodeValueDate,
                            isExpanded: false // Default to false as requested
                        }
                    });
                }
            });

            if (nodesToAdd.length > 0) {
                cy.add(nodesToAdd);
                // Run layout to position new nodes
                cy.layout({ name: 'cose', animate: true }).run();
                console.log("Added " + nodesToAdd.length + " nodes to graph");
            } else {
                console.log("No new nodes to add");
            }
        },

        clear: function () {
            if (cy) cy.elements().remove();
        }
    };

    // Expose Graph globally
    window.Graph = Graph;

})();
