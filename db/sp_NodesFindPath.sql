USE [IAS]
GO

/****** Object:  StoredProcedure [graphdb].[sp_NodesFindPath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [graphdb].[sp_NodesFindPath]
    @ViewGroupID INT,
    @SourceNodeIdentities [graphdb].[NodeIdentityTable] READONLY,
    @MaxDepth INT = 4,
    @Lang NVARCHAR(10) = 'en-US'
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Get Source Node Data IDs
    DECLARE @SourceNodeIDs TABLE (NodeDataID BIGINT, GroupNodeID INT, NodeValueID NVARCHAR(128));
    
    INSERT INTO @SourceNodeIDs (NodeDataID, GroupNodeID, NodeValueID)
    SELECT DISTINCT N.NodeDataID, S.GroupNodeID, S.NodeValueID
    FROM [graphdb].[vNodeData] N
    INNER JOIN @SourceNodeIdentities S 
        ON N.GroupNodeID = S.GroupNodeID 
        AND N.NodeValueID = S.NodeValueID;

    -- If less than 2 nodes found, we can't find a path
    IF (SELECT COUNT(*) FROM @SourceNodeIDs) < 2
    BEGIN
        SELECT TOP 0 * FROM [graphdb].[vRelationData];
        RETURN;
    END

    -- 2. Iterative BFS to find paths
    -- We will expand from all source nodes simultaneously and look for intersections
    
    -- Table to store visited nodes: NodeDataID -> (Depth, OriginSourceID)
    CREATE TABLE #Visited (
        NodeDataID BIGINT,
        Depth INT,
        OriginNodeDataID BIGINT,
        ParentNodeDataID BIGINT, -- To reconstruct path
        RelationDataID BIGINT,   -- Edge used to reach this node
        PRIMARY KEY (NodeDataID, OriginNodeDataID)
    );

    -- Initial state: Add source nodes
    INSERT INTO #Visited (NodeDataID, Depth, OriginNodeDataID, ParentNodeDataID, RelationDataID)
    SELECT NodeDataID, 0, NodeDataID, NULL, NULL
    FROM @SourceNodeIDs;

    DECLARE @CurrentDepth INT = 0;
    
    WHILE @CurrentDepth < @MaxDepth
    BEGIN
        -- Find neighbors of nodes at current depth
        -- We want to find nodes that haven't been visited BY THE SAME ORIGIN yet
        
        ;WITH NewNodes AS (
            -- Forward edges
            SELECT 
                R.TargetNodeDataID AS NodeDataID,
                @CurrentDepth + 1 AS Depth,
                V.OriginNodeDataID,
                V.NodeDataID AS ParentNodeDataID,
                R.RelationDataID
            FROM #Visited V
            INNER JOIN [graphdb].[vRelationData] R ON V.NodeDataID = R.SourceNodeDataID
            WHERE V.Depth = @CurrentDepth
              AND R.ViewGroupID = @ViewGroupID
            
            UNION ALL
            
            -- Backward edges
            SELECT 
                R.SourceNodeDataID AS NodeDataID,
                @CurrentDepth + 1 AS Depth,
                V.OriginNodeDataID,
                V.NodeDataID AS ParentNodeDataID,
                R.RelationDataID
            FROM #Visited V
            INNER JOIN [graphdb].[vRelationData] R ON V.NodeDataID = R.TargetNodeDataID
            WHERE V.Depth = @CurrentDepth
              AND R.ViewGroupID = @ViewGroupID
        ),
        RankedNodes AS (
            SELECT 
                NodeDataID,
                Depth,
                OriginNodeDataID,
                ParentNodeDataID,
                RelationDataID,
                ROW_NUMBER() OVER (PARTITION BY NodeDataID, OriginNodeDataID ORDER BY ParentNodeDataID) AS rn
            FROM NewNodes
            WHERE NOT EXISTS (
                  SELECT 1 FROM #Visited Existing 
                  WHERE Existing.NodeDataID = NewNodes.NodeDataID 
                    AND Existing.OriginNodeDataID = NewNodes.OriginNodeDataID
              )
        )
        INSERT INTO #Visited (NodeDataID, Depth, OriginNodeDataID, ParentNodeDataID, RelationDataID)
        SELECT NodeDataID, Depth, OriginNodeDataID, ParentNodeDataID, RelationDataID
        FROM RankedNodes
        WHERE rn = 1;
        
        IF @@ROWCOUNT = 0 BREAK; -- No new nodes found

        SET @CurrentDepth = @CurrentDepth + 1;
    END

    -- 3. Identify Intersection Points
    -- An intersection is a node that has been visited by at least two DIFFERENT origins
    -- OR a node that IS an origin and was visited by another origin
    
    -- We want to return all edges that form the shortest paths between any pair of source nodes.
    -- This is complex to reconstruct perfectly in SQL without a graph engine.
    -- Simplified approach: Return the subgraph formed by the BFS traversal that connects the sources.
    
    -- Better approach for "Find Path":
    -- Just return the edges found in the BFS that eventually lead to another source node.
    
    -- Let's try a different approach: Bidirectional Search is hard in SQL sets.
    -- Let's just return the subgraph of visited nodes where the node is part of a path between two sources.
    
    -- Filter #Visited to keep only nodes that are part of a valid path.
    -- A node is valid if it can reach a SourceNode (other than its Origin) or is reached by one.
    
    -- Actually, simpler: Just return all visited edges. The client can filter? No, too much data.
    
    -- Let's select edges that connect nodes which are "useful".
    -- A node is useful if it's on a path between two different SourceIDs.
    
    -- Reconstruct paths:
    -- Find "Meeting Points": Nodes visited by > 1 Origin
    SELECT DISTINCT NodeDataID 
    INTO #MeetingPoints
    FROM #Visited
    GROUP BY NodeDataID
    HAVING COUNT(DISTINCT OriginNodeDataID) > 1;
    
    -- Also include cases where one source reached another source directly
    INSERT INTO #MeetingPoints
    SELECT DISTINCT V.NodeDataID
    FROM #Visited V
    WHERE V.NodeDataID IN (SELECT NodeDataID FROM @SourceNodeIDs)
      AND V.OriginNodeDataID <> V.NodeDataID;

    -- If no meeting points, no paths found
    IF NOT EXISTS (SELECT 1 FROM #MeetingPoints)
    BEGIN
        SELECT TOP 0 * FROM [graphdb].[vRelationData];
        RETURN;
    END

    -- Backtrack from MeetingPoints to Origins to get the valid paths
    -- We need to select all rows from #Visited that are ancestors of MeetingPoints
    
    ;WITH ValidPathNodes AS (
        -- Start with meeting points
        SELECT V.*
        FROM #Visited V
        INNER JOIN #MeetingPoints M ON V.NodeDataID = M.NodeDataID
        
        UNION ALL
        
        -- Recursive step: Get parents
        SELECT P.*
        FROM #Visited P
        INNER JOIN ValidPathNodes C ON P.NodeDataID = C.ParentNodeDataID 
                                   AND P.OriginNodeDataID = C.OriginNodeDataID
    )
    SELECT DISTINCT RelationDataID
    INTO #ValidEdges
    FROM ValidPathNodes
    WHERE RelationDataID IS NOT NULL;

    -- 4. Return the Relation Data
    SELECT 
        R.RelationDataID,
        R.SourceNodeDataID,
        R.TargetNodeDataID,
        R.TargetNodeID,
        N.GroupNodeID AS TargetGroupNodeID,
        R.TargetNodeValueID,
        CASE WHEN @Lang = 'ar-AE' THEN R.TargetNodeValueAr ELSE R.TargetNodeValueEn END AS TargetNodeValue,
        N.ColumnColor AS TargetNodeColor,
        R.TargetNodeValueDate,
        CASE WHEN @Lang = 'ar-AE' THEN R.RelationAr ELSE R.RelationEn END AS Relation,
        
        -- Also return Source Node Info (needed for graph construction if not present)
        SN.GroupNodeID AS SourceGroupNodeID,
        R.SourceNodeValueID,
        CASE WHEN @Lang = 'ar-AE' THEN R.SourceNodeValueAr ELSE R.SourceNodeValueEn END AS SourceNodeValue,
        SN.ColumnColor AS SourceNodeColor
        
    FROM [graphdb].[vRelationData] R
    INNER JOIN #ValidEdges VE ON R.RelationDataID = VE.RelationDataID
    INNER JOIN [graphdb].[Nodes] N ON R.TargetNodeID = N.NodeID
    INNER JOIN [graphdb].[Nodes] SN ON R.SourceNodeID = SN.NodeID
    
    UNION
    
    -- Also include the reverse edges if they exist in the path (since our BFS was directed)
    -- Or just rely on the fact that if A->B is in path, B->A might not be needed for visualization
    -- But for completeness, let's just return what we found.
    
    -- Wait, we also need the edges connecting the meeting points if they are direct?
    -- The BFS captures edges TO the meeting point.
    -- If two BFS frontiers met at node M (Origin A -> ... -> M <- ... <- Origin B),
    -- We have the path A->M and B->M. So we have A-M-B.
    -- But the edges are directed A->M and B->M.
    -- In the graph, this will show A -> M <- B. This is a valid path in the underlying graph.
    
    -- What if the path is A -> B -> C?
    -- Origin A reaches B (Depth 1). Origin B reaches B (Depth 0).
    -- Meeting point is B.
    -- Path A->B is captured.
    -- Origin B reaches C (Depth 1). Origin C reaches C (Depth 0).
    -- Meeting point C.
    -- Path B->C is captured.
    -- So A->B and B->C are captured.
    
    SELECT TOP 0 
        R.RelationDataID,
        R.SourceNodeDataID,
        R.TargetNodeDataID,
        R.TargetNodeID,
        N.GroupNodeID AS TargetGroupNodeID,
        R.TargetNodeValueID,
        CASE WHEN @Lang = 'ar-AE' THEN R.TargetNodeValueAr ELSE R.TargetNodeValueEn END AS TargetNodeValue,
        N.ColumnColor AS TargetNodeColor,
        R.TargetNodeValueDate,
        CASE WHEN @Lang = 'ar-AE' THEN R.RelationAr ELSE R.RelationEn END AS Relation,
        SN.GroupNodeID AS SourceGroupNodeID,
        R.SourceNodeValueID,
        CASE WHEN @Lang = 'ar-AE' THEN R.SourceNodeValueAr ELSE R.SourceNodeValueEn END AS SourceNodeValue,
        SN.ColumnColor AS SourceNodeColor
    FROM [graphdb].[vRelationData] R
    INNER JOIN [graphdb].[Nodes] N ON R.TargetNodeID = N.NodeID
    INNER JOIN [graphdb].[Nodes] SN ON R.SourceNodeID = SN.NodeID
    WHERE 1=0; -- Dummy union to match types if needed

    -- Cleanup
    DROP TABLE #Visited;
    DROP TABLE #MeetingPoints;
    DROP TABLE #ValidEdges;
END
GO
