(function () {
    'use strict';

    var Graph = window.Graph;

    // Cache for pie chart SVGs
    Graph.pieChartCache = {};

    // Create pie chart SVG for multi-color nodes
    Graph.createPieChart = function (colors) {
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
    };

    Graph.changeLayout = function (layoutName, shouldAnimate) {
        if (!Graph.cy) return;

        var layoutConfig = {
            name: layoutName,
            animate: shouldAnimate === true, // Use flag, default to false if undefined
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
                layoutConfig.numIter = 500; // Increased for better ("neater") layout quality
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

        var layout = Graph.cy.layout(layoutConfig);
        layout.run();

    };

    // Client-Side Path Finding (existing)
    Graph.paths = {};
    Graph.pathColors = ['#ff0000', '#00ff00', '#0000ff', '#ff00ff', '#00ffff', '#ffa500'];
    Graph.pathColorIndex = 0;

    Graph.findShortestPath = function (sourceId, targetId) {
        if (!Graph.cy) return { found: false };

        var source = Graph.cy.getElementById(sourceId);
        var target = Graph.cy.getElementById(targetId);

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
        var aStar = Graph.cy.elements().aStar({
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
    };

    Graph.togglePath = function (pathId, visible) {
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
    };

    Graph.removePath = function (pathId) {
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
    };

    Graph.hiddenLeaves = null;

    Graph.toggleLeaves = function (shouldHide) {
        if (!Graph.cy) return;

        if (shouldHide) {
            // Hide leaves
            var leaves = Graph.cy.nodes().filter(function (ele) {
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
    };

    Graph.saveAsImage = function () {
        if (!Graph.cy) return;
        var png64 = Graph.cy.png({ full: true, scale: 2, bg: 'white' });
        var link = document.createElement('a');
        link.download = 'graph-view-' + new Date().getTime() + '.png';
        link.href = png64;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    Graph.blinkInterval = null;

    Graph.searchNodes = function (searchList) {
        // Stop existing blink and clear highlights
        if (Graph.blinkInterval) {
            clearInterval(Graph.blinkInterval);
            Graph.blinkInterval = null;
        }
        if (Graph.cy) {
            Graph.cy.nodes().removeClass('blink-highlight');
        }

        if (!Graph.cy || !searchList || searchList.length === 0) return;

        Graph.cy.batch(function () {
            var allFoundNodes = Graph.cy.collection();

            searchList.forEach(function (term) {
                var lowerTerm = term.toLowerCase();
                // Find nodes where ID or Label contains the term
                var found = Graph.cy.nodes().filter(function (ele) {
                    var id = ele.id().toLowerCase();
                    var label = (ele.data('label') || '').toLowerCase();
                    return id.indexOf(lowerTerm) !== -1 || label.indexOf(lowerTerm) !== -1;
                });
                allFoundNodes = allFoundNodes.union(found);
            });

            if (allFoundNodes.length > 0) {
                // Select and Zoom
                Graph.cy.nodes().unselect();
                allFoundNodes.select();
                Graph.cy.fit(allFoundNodes, 50);

                // Infinite Blink Animation
                var isHighlighted = false;
                Graph.blinkInterval = setInterval(function () {
                    if (isHighlighted) {
                        allFoundNodes.removeClass('blink-highlight');
                    } else {
                        allFoundNodes.addClass('blink-highlight');
                    }
                    isHighlighted = !isHighlighted;
                }, 500);

                if (Graph.showStatus) {
                    Graph.showStatus("Found " + allFoundNodes.length + " nodes", "success");
                }
            } else {
                if (Graph.showStatus) {
                    Graph.showStatus("No nodes found matching your list", "info");
                }
            }
        });
    };


    Graph.openNodeDetailsInParent = function (nodeData) {
        if (window.parent && window.parent.showNodeDetails) {
            // Extract IDs
            var nodeId = nodeData.id;
            var groupNodeId = 'N/A';
            var nodeValueId = 'N/A';
            var nodeValue = nodeData.label || 'N/A';

            // Try to find properties in the node data if available
            if (Graph.cy) {
                var cyNode = Graph.cy.getElementById(nodeId);
                if (cyNode && cyNode.length > 0) {
                    var props = cyNode.data('properties');
                    if (props && props.length > 0) {
                        groupNodeId = props[0].GroupNodeID;
                        nodeValueId = props[0].NodeValueID;
                    }
                }
            }

            window.parent.showNodeDetails(nodeId, groupNodeId, nodeValueId, nodeValue);
        } else {
            console.warn("window.parent.showNodeDetails not found");
            alert("Node ID: " + nodeData.id);
        }
    };

})();
