USE [IAS]
GO
/****** Object:  Schema [graphdb]    Script Date: 12/4/2025 7:17:07 AM ******/
CREATE SCHEMA [graphdb]
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeDataIDTable]    Script Date: 12/4/2025 7:17:07 AM ******/
CREATE TYPE [graphdb].[NodeDataIDTable] AS TABLE(
	[NodeDataID] [bigint] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[NodeDataID] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeFilterTable]    Script Date: 12/4/2025 7:17:07 AM ******/
CREATE TYPE [graphdb].[NodeFilterTable] AS TABLE(
	[NodeID] [int] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeIdentityTable]    Script Date: 12/4/2025 7:17:07 AM ******/
CREATE TYPE [graphdb].[NodeIdentityTable] AS TABLE(
	[GroupNodeID] [int] NOT NULL,
	[NodeValueID] [nvarchar](128) NOT NULL
)
GO
/****** Object:  Table [graphdb].[Relations]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[Relations](
	[RelationID] [int] IDENTITY(1,1) NOT NULL,
	[ViewGroupID] [int] NOT NULL,
	[SourceNodeID] [int] NOT NULL,
	[SearchNodeID] [int] NOT NULL,
	[DisplayNodeID] [int] NOT NULL,
	[RelationNodeID] [int] NULL,
	[RelationEn] [nvarchar](128) NULL,
	[RelationAr] [nvarchar](128) NULL,
	[isActive] [bit] NOT NULL,
 CONSTRAINT [PK_Relations] PRIMARY KEY CLUSTERED 
(
	[RelationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[Nodes]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[Nodes](
	[NodeID] [int] IDENTITY(1,1) NOT NULL,
	[GroupNodeID] [int] NULL,
	[ColumnID] [sysname] NOT NULL,
	[ColumnEn] [nvarchar](200) NULL,
	[ColumnAr] [nvarchar](200) NULL,
	[ColumnColor] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_SeedColumnCatalog] PRIMARY KEY CLUSTERED 
(
	[NodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[GroupNode]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[GroupNode](
	[GroupNodeID] [int] NOT NULL,
	[GroupNodeEn] [nvarchar](200) NOT NULL,
	[GroupNodeAr] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_GroupNode] PRIMARY KEY CLUSTERED 
(
	[GroupNodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [graphdb].[vRelations]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/********************************************************************
  View: [graphdb].[vRelations]

  Purpose:
    - To display all relationships with descriptive information
      for:
        • SourceNode
        • SearchNode
        • DisplayNode
        • RelationNode
    - Includes each node's GroupNode details (ID, En, Ar).

  Output highlights:
    RelationID, RelationEn, RelationAr, isActive
    SourceNode*, SearchNode*, DisplayNode*, RelationNode*
    Each node includes: ColumnEn/Ar, Color, GroupNodeEn/Ar 
*********************************************************************/
CREATE   VIEW [graphdb].[vRelations]
AS
SELECT
    r.RelationID,
	r.ViewGroupID,
    ----------------------------------------------------------
    -- Source Node
    ----------------------------------------------------------
    r.SourceNodeID,
    s.ColumnID        AS SourceColumnID,
    s.ColumnEn         AS SourceColumnEn,
    s.ColumnAr         AS SourceColumnAr,
    s.ColumnColor      AS SourceColor,
    s.GroupNodeID      AS SourceGroupNodeID,
    gs.GroupNodeEn     AS SourceGroupEn,
    gs.GroupNodeAr     AS SourceGroupAr,

    ----------------------------------------------------------
    -- Search Node
    ----------------------------------------------------------
    r.SearchNodeID,
    se.ColumnID       AS SearchColumnID,
    se.ColumnEn        AS SearchColumnEn,
    se.ColumnAr        AS SearchColumnAr,
    se.ColumnColor     AS SearchColor,
    se.GroupNodeID     AS SearchGroupNodeID,
    gse.GroupNodeEn    AS SearchGroupEn,
    gse.GroupNodeAr    AS SearchGroupAr,

    ----------------------------------------------------------
    -- Display Node
    ----------------------------------------------------------
    r.DisplayNodeID,
    d.ColumnID        AS DisplayColumnID,
    d.ColumnEn         AS DisplayColumnEn,
    d.ColumnAr         AS DisplayColumnAr,
    d.ColumnColor      AS DisplayColor,
    d.GroupNodeID      AS DisplayGroupNodeID,
    gd.GroupNodeEn     AS DisplayGroupEn,
    gd.GroupNodeAr     AS DisplayGroupAr,

    ----------------------------------------------------------
    -- Relation Node
    ----------------------------------------------------------
    r.RelationNodeID,
    rn.ColumnID       AS RelationColumnID,
    rn.ColumnEn        AS RelationColumnEn,
    rn.ColumnAr        AS RelationColumnAr,
    rn.ColumnColor     AS RelationColor,
    rn.GroupNodeID     AS RelationGroupNodeID,
    grn.GroupNodeEn    AS RelationGroupEn,
    grn.GroupNodeAr    AS RelationGroupAr,

    ----------------------------------------------------------
    -- Relation details
    ----------------------------------------------------------
    r.RelationEn,
    r.RelationAr,
    r.isActive
FROM graphdb.Relations AS r
LEFT JOIN graphdb.Nodes AS s   ON r.SourceNodeID   = s.NodeID
LEFT JOIN graphdb.Nodes AS se  ON r.SearchNodeID   = se.NodeID
LEFT JOIN graphdb.Nodes AS d   ON r.DisplayNodeID  = d.NodeID
LEFT JOIN graphdb.Nodes AS rn  ON r.RelationNodeID = rn.NodeID

-- Join each node’s GroupNode
LEFT JOIN graphdb.GroupNode AS gs  ON s.GroupNodeID   = gs.GroupNodeID
LEFT JOIN graphdb.GroupNode AS gse ON se.GroupNodeID  = gse.GroupNodeID
LEFT JOIN graphdb.GroupNode AS gd  ON d.GroupNodeID   = gd.GroupNodeID
LEFT JOIN graphdb.GroupNode AS grn ON rn.GroupNodeID  = grn.GroupNodeID;
GO
/****** Object:  Table [graphdb].[NodeData]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[NodeData](
	[NodeDataID] [bigint] IDENTITY(1,1) NOT NULL,
	[ViewGroupID] [int] NOT NULL,
	[NodeID] [int] NOT NULL,
	[NodeValueID] [nvarchar](128) NOT NULL,
	[NodeValueEn] [nvarchar](400) NULL,
	[NodeValueAr] [nvarchar](400) NULL,
	[NodeValueDate] [date] NULL,
 CONSTRAINT [PK_NodeData] PRIMARY KEY CLUSTERED 
(
	[NodeDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_NodeData] UNIQUE NONCLUSTERED 
(
	[ViewGroupID] ASC,
	[NodeID] ASC,
	[NodeValueID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [graphdb].[vNodeData]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [graphdb].[vNodeData]
AS
SELECT nd.NodeDataID, nd.ViewGroupID, nd.NodeID, n.GroupNodeID, nd.NodeValueID, nd.NodeValueEn, nd.NodeValueAr, nd.NodeValueDate, n.ColumnID, n.ColumnEn, n.ColumnAr, n.ColumnColor, g.GroupNodeEn, g.GroupNodeAr
FROM     graphdb.NodeData AS nd INNER JOIN
                  graphdb.Nodes AS n ON nd.NodeID = n.NodeID INNER JOIN
                  graphdb.GroupNode AS g ON n.GroupNodeID = g.GroupNodeID
GO
/****** Object:  Table [graphdb].[RelationData]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[RelationData](
	[RelationDataID] [bigint] IDENTITY(1,1) NOT NULL,
	[ViewGroupID] [int] NOT NULL,
	[SourceNodeDataID] [bigint] NOT NULL,
	[TargetNodeDataID] [bigint] NOT NULL,
	[RelationEn] [nvarchar](128) NULL,
	[RelationAr] [nvarchar](128) NULL,
	[RelationValueDate] [date] NULL,
 CONSTRAINT [PK_RelationData] PRIMARY KEY CLUSTERED 
(
	[RelationDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [graphdb].[vRelationData]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [graphdb].[vRelationData]
AS
SELECT 
    rd.RelationDataID,
    rd.ViewGroupID,
    rd.SourceNodeDataID,
    snd.NodeID AS SourceNodeID,
	sn.ColumnColor as SourceNodeColor,
    sn.GroupNodeID AS SourceGroupNodeID,
	sgn.GroupNodeEn as SourceGroupNodeEn,
	sgn.GroupNodeAr as SourceGroupNodeAr,
    snd.NodeValueID AS SourceNodeValueID,
    snd.NodeValueEn AS SourceNodeValueEn,
    snd.NodeValueAr AS SourceNodeValueAr,
    snd.NodeValueDate AS SourceNodeValueDate,
    rd.TargetNodeDataID,
    tnd.NodeID AS TargetNodeID,
	tn.ColumnColor as TargetNodeColor,
    tn.GroupNodeID AS TargetGroupNodeID,
	tgn.GroupNodeEn as TargetGroupNodeEn,
	tgn.GroupNodeAr as TargetGroupNodeAr,
    tnd.NodeValueID AS TargetNodeValueID,
    tnd.NodeValueEn AS TargetNodeValueEn,
    tnd.NodeValueAr AS TargetNodeValueAr,
    tnd.NodeValueDate AS TargetNodeValueDate,
    rd.RelationEn,
    rd.RelationAr,
    rd.RelationValueDate
FROM [graphdb].[RelationData] rd
INNER JOIN [graphdb].[NodeData] snd ON rd.SourceNodeDataID = snd.NodeDataID
INNER JOIN [graphdb].[Nodes] sn ON snd.NodeID = sn.NodeID
INNER JOIN [graphdb].[GroupNode] sgn on sn.GroupNodeID=sgn.GroupNodeID
INNER JOIN [graphdb].[NodeData] tnd ON rd.TargetNodeDataID = tnd.NodeDataID
INNER JOIN [graphdb].[Nodes] tn ON tnd.NodeID = tn.NodeID
INNER JOIN [graphdb].[GroupNode] tgn on tn.GroupNodeID=tgn.GroupNodeID
GO
/****** Object:  Table [graphdb].[ViewColumns]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[ViewColumns](
	[ViewColumnID] [int] IDENTITY(1,1) NOT NULL,
	[ViewID] [int] NOT NULL,
	[ColumnID] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_ViewColumns] PRIMARY KEY CLUSTERED 
(
	[ViewColumnID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[ViewGroupLists]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[ViewGroupLists](
	[ViewGroupListID] [int] IDENTITY(1,1) NOT NULL,
	[ViewGroupID] [int] NOT NULL,
	[ViewID] [int] NOT NULL,
 CONSTRAINT [PK_ViewGroupLists] PRIMARY KEY CLUSTERED 
(
	[ViewGroupListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[ViewGroups]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[ViewGroups](
	[ViewGroupID] [int] IDENTITY(1,1) NOT NULL,
	[ViewGroupNameEn] [nvarchar](200) NOT NULL,
	[ViewGroupNameAr] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_ViewGroups] PRIMARY KEY CLUSTERED 
(
	[ViewGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[Views]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[Views](
	[ViewID] [int] IDENTITY(1,1) NOT NULL,
	[ViewDescriptionEn] [nvarchar](200) NOT NULL,
	[ViewDescriptionAr] [nvarchar](200) NOT NULL,
	[ViewName] [nvarchar](128) NOT NULL,
	[ViewDB] [nvarchar](128) NOT NULL,
	[ViewSchema] [nvarchar](128) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ViewID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [graphdb].[Nodes] ADD  CONSTRAINT [DF_Nodes_ColumnColor]  DEFAULT (N'#b3ffff') FOR [ColumnColor]
GO
ALTER TABLE [graphdb].[Relations] ADD  CONSTRAINT [DF_Relations_isActive]  DEFAULT ((0)) FOR [isActive]
GO
ALTER TABLE [graphdb].[NodeData]  WITH CHECK ADD  CONSTRAINT [FK_NodeData_Nodes] FOREIGN KEY([NodeID])
REFERENCES [graphdb].[Nodes] ([NodeID])
GO
ALTER TABLE [graphdb].[NodeData] CHECK CONSTRAINT [FK_NodeData_Nodes]
GO
ALTER TABLE [graphdb].[NodeData]  WITH CHECK ADD  CONSTRAINT [FK_NodeData_ViewGroups] FOREIGN KEY([ViewGroupID])
REFERENCES [graphdb].[ViewGroups] ([ViewGroupID])
GO
ALTER TABLE [graphdb].[NodeData] CHECK CONSTRAINT [FK_NodeData_ViewGroups]
GO
ALTER TABLE [graphdb].[Nodes]  WITH CHECK ADD  CONSTRAINT [FK_Nodes_GroupNode] FOREIGN KEY([GroupNodeID])
REFERENCES [graphdb].[GroupNode] ([GroupNodeID])
ON DELETE CASCADE
GO
ALTER TABLE [graphdb].[Nodes] CHECK CONSTRAINT [FK_Nodes_GroupNode]
GO
ALTER TABLE [graphdb].[RelationData]  WITH CHECK ADD  CONSTRAINT [FK_RelationData_NodeData_Source] FOREIGN KEY([SourceNodeDataID])
REFERENCES [graphdb].[NodeData] ([NodeDataID])
GO
ALTER TABLE [graphdb].[RelationData] CHECK CONSTRAINT [FK_RelationData_NodeData_Source]
GO
ALTER TABLE [graphdb].[RelationData]  WITH CHECK ADD  CONSTRAINT [FK_RelationData_NodeData_Target] FOREIGN KEY([TargetNodeDataID])
REFERENCES [graphdb].[NodeData] ([NodeDataID])
GO
ALTER TABLE [graphdb].[RelationData] CHECK CONSTRAINT [FK_RelationData_NodeData_Target]
GO
ALTER TABLE [graphdb].[RelationData]  WITH CHECK ADD  CONSTRAINT [FK_RelationData_ViewGroups] FOREIGN KEY([ViewGroupID])
REFERENCES [graphdb].[ViewGroups] ([ViewGroupID])
GO
ALTER TABLE [graphdb].[RelationData] CHECK CONSTRAINT [FK_RelationData_ViewGroups]
GO
ALTER TABLE [graphdb].[Relations]  WITH CHECK ADD  CONSTRAINT [FK_Relations_Nodes] FOREIGN KEY([SourceNodeID])
REFERENCES [graphdb].[Nodes] ([NodeID])
ON DELETE CASCADE
GO
ALTER TABLE [graphdb].[Relations] CHECK CONSTRAINT [FK_Relations_Nodes]
GO
ALTER TABLE [graphdb].[Relations]  WITH CHECK ADD  CONSTRAINT [FK_Relations_Nodes1] FOREIGN KEY([SearchNodeID])
REFERENCES [graphdb].[Nodes] ([NodeID])
GO
ALTER TABLE [graphdb].[Relations] CHECK CONSTRAINT [FK_Relations_Nodes1]
GO
ALTER TABLE [graphdb].[Relations]  WITH CHECK ADD  CONSTRAINT [FK_Relations_Nodes2] FOREIGN KEY([DisplayNodeID])
REFERENCES [graphdb].[Nodes] ([NodeID])
GO
ALTER TABLE [graphdb].[Relations] CHECK CONSTRAINT [FK_Relations_Nodes2]
GO
ALTER TABLE [graphdb].[Relations]  WITH CHECK ADD  CONSTRAINT [FK_Relations_Nodes3] FOREIGN KEY([RelationNodeID])
REFERENCES [graphdb].[Nodes] ([NodeID])
GO
ALTER TABLE [graphdb].[Relations] CHECK CONSTRAINT [FK_Relations_Nodes3]
GO
ALTER TABLE [graphdb].[Relations]  WITH CHECK ADD  CONSTRAINT [FK_Relations_ViewGroups] FOREIGN KEY([ViewGroupID])
REFERENCES [graphdb].[ViewGroups] ([ViewGroupID])
GO
ALTER TABLE [graphdb].[Relations] CHECK CONSTRAINT [FK_Relations_ViewGroups]
GO
ALTER TABLE [graphdb].[ViewColumns]  WITH CHECK ADD  CONSTRAINT [FK_ViewColumns_Views] FOREIGN KEY([ViewID])
REFERENCES [graphdb].[Views] ([ViewID])
GO
ALTER TABLE [graphdb].[ViewColumns] CHECK CONSTRAINT [FK_ViewColumns_Views]
GO
ALTER TABLE [graphdb].[ViewGroupLists]  WITH CHECK ADD  CONSTRAINT [FK_ViewGroupLists_ViewGroups] FOREIGN KEY([ViewGroupID])
REFERENCES [graphdb].[ViewGroups] ([ViewGroupID])
GO
ALTER TABLE [graphdb].[ViewGroupLists] CHECK CONSTRAINT [FK_ViewGroupLists_ViewGroups]
GO
ALTER TABLE [graphdb].[ViewGroupLists]  WITH CHECK ADD  CONSTRAINT [FK_ViewGroupLists_Views] FOREIGN KEY([ViewID])
REFERENCES [graphdb].[Views] ([ViewID])
GO
ALTER TABLE [graphdb].[ViewGroupLists] CHECK CONSTRAINT [FK_ViewGroupLists_Views]
GO
/****** Object:  StoredProcedure [graphdb].[sp_GraphGenerate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_GraphGenerate]
  @PruneMissing BIT = 1
AS
/*
EXEC [graphdb].[sp_GraphGenerate]
*/
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRAN;

    -- 1️⃣ Generate/update Nodes and ViewColumns
    EXEC [graphdb].[sp_NodesGenerate] @PruneMissing;

    -- 2️⃣ Generate/update Relations per ViewGroup
    EXEC [graphdb].[sp_RelationsGenerate] @PruneMissing;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_GroupNodeList]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_GroupNodeList]
(
    @Lang NVARCHAR(10) = 'en-US'  -- 'En' or 'Ar'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        GroupNodeID,
        GroupNodeEn,
        GroupNodeAr,
        CASE 
            WHEN LOWER(@Lang) = N'ar-AE' THEN GroupNodeAr
            ELSE GroupNodeEn
        END AS GroupNodeName
    FROM [graphdb].[GroupNode]
    ORDER BY 
        CASE 
            WHEN LOWER(@Lang) = N'ar-AE' THEN GroupNodeAr
            ELSE GroupNodeEn
        END;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodeDataAutoComplete]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Updated autocomplete to return GroupNodeID and NodeValueID for identity-based system
CREATE   PROCEDURE [graphdb].[sp_NodeDataAutoComplete]
    @NodeID     INT,
    @SearchText NVARCHAR(200),
    @TopCount   INT = 20,
    @Lang       NVARCHAR(10) = N'en-US'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @SearchText = ISNULL(@SearchText, N'');
        SET @Lang = LOWER(@Lang);

        DECLARE @LangColumn NVARCHAR(50);

        -- Choose which language column to display
        SET @LangColumn = CASE 
                            WHEN @Lang = N'ar-ae' THEN N'NodeValueAr'
                            ELSE N'NodeValueEn'
                          END;

        -- Return distinct identities with GroupNodeID and NodeValueID
        IF @LangColumn = N'NodeValueAr'
        BEGIN
            SELECT DISTINCT TOP (@TopCount)
                v.GroupNodeID,
                v.NodeValueID,
                v.NodeValueAr AS [NodeValue]
            FROM [graphdb].[vNodeData] AS v
            WHERE v.NodeID = @NodeID
              AND (
                    @SearchText = N'' 
                    OR v.NodeValueEn LIKE N'%' + @SearchText + N'%'
                    OR v.NodeValueAr LIKE N'%' + @SearchText + N'%'
                  )
              AND v.NodeValueAr IS NOT NULL 
              AND LTRIM(RTRIM(v.NodeValueAr)) <> N''
            ORDER BY v.NodeValueAr;
        END
        ELSE
        BEGIN
            SELECT DISTINCT TOP (@TopCount)
                v.GroupNodeID,
                v.NodeValueID,
                v.NodeValueEn AS [NodeValue]
            FROM [graphdb].[vNodeData] AS v
            WHERE v.NodeID = @NodeID
              AND (
                    @SearchText = N'' 
                    OR v.NodeValueEn LIKE N'%' + @SearchText + N'%'
                    OR v.NodeValueAr LIKE N'%' + @SearchText + N'%'
                  )
              AND v.NodeValueEn IS NOT NULL 
              AND LTRIM(RTRIM(v.NodeValueEn)) <> N''
            ORDER BY v.NodeValueEn;
        END

    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodeDataGenerate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/********************************************************************
  [graphdb].[sp_NodeDataGenerate]

  Purpose:
    Populate [graphdb].[NodeData] from all registered views in a
    ViewGroup, using metadata:

      - [graphdb].[ViewGroups]
      - [graphdb].[ViewGroupLists]
      - [graphdb].[Views]
      - [graphdb].[ViewColumns]
      - [graphdb].[Nodes] (ColumnID = ID_*_ID)

    Column naming pattern per group (A/B/C/D/R...):
      ID_*_ID          → NodeValueID   (converted to NVARCHAR(128))
      ENTEXT_*_ENTEXT  → NodeValueEn
      ARTEXT_*_ARTEXT  → NodeValueAr
      DATE_*_DATE      → NodeValueDate

  Business rules:
    - Key: (ViewGroupID, NodeID, NodeValueID) must be unique.
    - Skip rows where:
         * NodeValueID is NULL or empty string after conversion
         * AND both NodeValueEn and NodeValueAr are NULL
    - If multiple rows for the same key:
        * Take the row(s) with the latest NodeValueDate
          (NULL treated as '1900-01-01').
        * At that date:
            - If EN is NULL, use AR.
            - If AR is NULL, use EN.
            - If multiple different values exist, pick one via MAX()
              (no error).

  Usage:
    EXEC [graphdb].[sp_NodeDataGenerate];              -- all ViewGroups
    EXEC [graphdb].[sp_NodeDataGenerate] @ViewGroupID = 1;  -- single group
*********************************************************************/
CREATE   PROCEDURE [graphdb].[sp_NodeDataGenerate]
    @ViewGroupID INT = NULL      -- NULL = all groups
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------------
        -- 1. Resolve all (ViewGroupID, ViewID, View, Node) combos
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#Sources') IS NOT NULL DROP TABLE #Sources;

        CREATE TABLE #Sources
        (
            ViewGroupID   INT,
            ViewID        INT,
            ViewDB        NVARCHAR(128),
            ViewSchema    NVARCHAR(128),
            ViewNameEn    NVARCHAR(128),
            NodeID        INT,
            IdColumn      SYSNAME,
            DateColumn    SYSNAME,
            EnColumn      SYSNAME,
            ArColumn      SYSNAME
        );

        ;WITH IDCols AS (
            SELECT
                vgl.ViewGroupID,
                v.ViewID,
                v.ViewDB,
                v.ViewSchema,
                v.ViewName,
                vc.ColumnID,        -- e.g. ID_A_ID
                n.NodeID
            FROM graphdb.ViewGroupLists vgl
            JOIN graphdb.Views v
              ON v.ViewID = vgl.ViewID
            JOIN graphdb.ViewColumns vc
              ON vc.ViewID = v.ViewID
            JOIN graphdb.Nodes n
              ON n.ColumnID = vc.ColumnID
            WHERE vc.ColumnID LIKE N'ID\_%\_ID' ESCAPE N'\'
              AND (@ViewGroupID IS NULL OR vgl.ViewGroupID = @ViewGroupID)
        )
        INSERT INTO #Sources (ViewGroupID, ViewID, ViewDB, ViewSchema, ViewNameEn,
                              NodeID, IdColumn, DateColumn, EnColumn, ArColumn)
        SELECT
            ViewGroupID,
            ViewID,
            ViewDB,
            ViewSchema,
            ViewName,
            NodeID,
            ColumnID AS IdColumn,
            -- derive the group key in the middle: ID_<X>_ID
            DateColumn = N'DATE_'   + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_DATE',
            EnColumn   = N'ENTEXT_' + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_ENTEXT',
            ArColumn   = N'ARTEXT_' + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_ARTEXT'
        FROM IDCols;

        ------------------------------------------------------------
        -- 2. Stage raw node values into #NodeDataRaw
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#NodeDataRaw') IS NOT NULL DROP TABLE #NodeDataRaw;

        CREATE TABLE #NodeDataRaw
        (
            ViewGroupID    INT,
            NodeID         INT,
            NodeValueID    NVARCHAR(128),
            NodeValueEn    NVARCHAR(400),
            NodeValueAr    NVARCHAR(400),
            NodeValueDate  DATE
        );

        DECLARE 
            @VGID       INT,
            @ViewID     INT,
            @ViewDB     NVARCHAR(128),
            @ViewSchema NVARCHAR(128),
            @ViewNameEn NVARCHAR(128),
            @NodeID     INT,
            @IdColumn   SYSNAME,
            @DateColumn SYSNAME,
            @EnColumn   SYSNAME,
            @ArColumn   SYSNAME,
            @sql        NVARCHAR(MAX);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT ViewGroupID, ViewID, ViewDB, ViewSchema, ViewNameEn,
                   NodeID, IdColumn, DateColumn, EnColumn, ArColumn
            FROM #Sources;

        OPEN cur;
        FETCH NEXT FROM cur INTO
            @VGID, @ViewID, @ViewDB, @ViewSchema, @ViewNameEn,
            @NodeID, @IdColumn, @DateColumn, @EnColumn, @ArColumn;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'
                INSERT INTO #NodeDataRaw
                    (ViewGroupID, NodeID, NodeValueID, NodeValueEn, NodeValueAr, NodeValueDate)
                SELECT
                    ' + CAST(@VGID AS NVARCHAR(20)) + N'          AS ViewGroupID,
                    ' + CAST(@NodeID AS NVARCHAR(20)) + N'        AS NodeID,
                    CONVERT(NVARCHAR(128), t.' + QUOTENAME(@IdColumn) + N') AS NodeValueID,
                    t.' + QUOTENAME(@EnColumn) + N'               AS NodeValueEn,
                    t.' + QUOTENAME(@ArColumn) + N'               AS NodeValueAr,
                    t.' + QUOTENAME(@DateColumn) + N'             AS NodeValueDate
                FROM ' + QUOTENAME(@ViewDB) + N'.' + QUOTENAME(@ViewSchema) + N'.' + QUOTENAME(@ViewNameEn) + N' AS t
                WHERE t.' + QUOTENAME(@IdColumn) + N' IS NOT NULL
                  AND CONVERT(NVARCHAR(128), t.' + QUOTENAME(@IdColumn) + N') <> N''''
                  AND (t.' + QUOTENAME(@EnColumn) + N' IS NOT NULL
                       OR t.' + QUOTENAME(@ArColumn) + N' IS NOT NULL);
            ';

            -- PRINT @sql;  -- uncomment for debugging
            EXEC sys.sp_executesql @sql;

            FETCH NEXT FROM cur INTO
                @VGID, @ViewID, @ViewDB, @ViewSchema, @ViewNameEn,
                @NodeID, @IdColumn, @DateColumn, @EnColumn, @ArColumn;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- Helpful index for big volumes
        CREATE NONCLUSTERED INDEX IX_NodeDataRaw_Key
        ON #NodeDataRaw (ViewGroupID, NodeID, NodeValueID, NodeValueDate);

        ------------------------------------------------------------
        -- 3. Deduplicate: latest date, pick one value
        ------------------------------------------------------------
        -- 3.1 Latest date per (ViewGroupID, NodeID, NodeValueID)
        IF OBJECT_ID('tempdb..#Latest') IS NOT NULL DROP TABLE #Latest;

        SELECT
            ViewGroupID,
            NodeID,
            NodeValueID,
            LatestDate = MAX(ISNULL(NodeValueDate, '19000101'))  -- treat NULL as 1900-01-01
        INTO #Latest
        FROM #NodeDataRaw
        GROUP BY ViewGroupID, NodeID, NodeValueID;

        CREATE NONCLUSTERED INDEX IX_Latest_Key
        ON #Latest (ViewGroupID, NodeID, NodeValueID, LatestDate);

        -- 3.2 Restrict to rows at latest date and collapse duplicates
        IF OBJECT_ID('tempdb..#NodeDataFinal') IS NOT NULL DROP TABLE #NodeDataFinal;

        ;WITH AtLatest AS (
            SELECT
                r.ViewGroupID,
                r.NodeID,
                r.NodeValueID,
                r.NodeValueEn,
                r.NodeValueAr,
                r.NodeValueDate
            FROM #Latest l
            JOIN #NodeDataRaw r
              ON  r.ViewGroupID                = l.ViewGroupID
              AND r.NodeID                     = l.NodeID
              AND r.NodeValueID                = l.NodeValueID
              AND ISNULL(r.NodeValueDate, '19000101') = l.LatestDate
        )
        SELECT
            a.ViewGroupID,
            a.NodeID,
            a.NodeValueID,
            a.NodeValueDate,
            -- Take ONE value deterministically with fallback:
            NodeValueEn = MAX(COALESCE(a.NodeValueEn, a.NodeValueAr)),
            NodeValueAr = MAX(COALESCE(a.NodeValueAr, a.NodeValueEn))
        INTO #NodeDataFinal
        FROM AtLatest a
        GROUP BY
            a.ViewGroupID,
            a.NodeID,
            a.NodeValueID,
            a.NodeValueDate;

        -- defensive: if anything slipped through with both EN and AR NULL, drop it
        DELETE FROM #NodeDataFinal
        WHERE NodeValueEn IS NULL AND NodeValueAr IS NULL;

        ------------------------------------------------------------
        -- 4. MERGE into graphdb.NodeData
        ------------------------------------------------------------
        MERGE graphdb.NodeData AS target
        USING #NodeDataFinal AS src
           ON  target.ViewGroupID  = src.ViewGroupID
           AND target.NodeID       = src.NodeID
           AND target.NodeValueID  = src.NodeValueID
        WHEN MATCHED THEN
            UPDATE SET
                target.NodeValueEn   = src.NodeValueEn,
                target.NodeValueAr   = src.NodeValueAr,
                target.NodeValueDate = src.NodeValueDate
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (ViewGroupID, NodeID, NodeValueID, NodeValueEn, NodeValueAr, NodeValueDate)
            VALUES (src.ViewGroupID, src.NodeID, src.NodeValueID, src.NodeValueEn, src.NodeValueAr, src.NodeValueDate)
        ;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;

        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesExpand]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    Update sp_NodesExpand to use NodeIdentityTable (GroupNodeID + NodeValueID)
    instead of NodeDataIDTable.
    
    Refactored to use [graphdb].[vRelationData] directly as requested.
*/

CREATE   PROCEDURE [graphdb].[sp_NodesExpand]
    @ViewGroupID INT,
    @SourceNodeIdentities [graphdb].[NodeIdentityTable] READONLY,  
    @FilterNodes [graphdb].[NodeFilterTable] READONLY,      
    @MaxNeighbors INT = 200,
    @Lang NVARCHAR(10) = 'en-US'
AS
BEGIN
    SET NOCOUNT ON;
	
    -- CTE to find relations matching the source identities
    WITH RankedRelations AS (
        SELECT 
            R.RelationDataID,
            R.ViewGroupID,
            R.SourceNodeID,
            R.SourceNodeValueID,
            R.SourceGroupNodeID,
			R.SourceNodeColor,
            R.TargetNodeID,
            R.TargetNodeValueID,
            R.TargetNodeValueEn,
            R.TargetNodeValueAr,
            R.TargetNodeValueDate,
            R.TargetGroupNodeID,
            R.TargetNodeColor,
            R.RelationEn,
            R.RelationAr,
            ROW_NUMBER() OVER (
                PARTITION BY R.SourceGroupNodeID, R.SourceNodeValueID 
                ORDER BY R.TargetNodeValueDate DESC
            ) AS RowNum
        FROM [graphdb].[vRelationData] R
        INNER JOIN @SourceNodeIdentities S ON R.SourceGroupNodeID = S.GroupNodeID  AND R.SourceNodeValueID = S.NodeValueID
        INNER JOIN @FilterNodes F ON R.TargetNodeID = F.NodeID
        WHERE R.ViewGroupID = @ViewGroupID  AND R.TargetNodeValueDate BETWEEN F.FromDate AND F.ToDate
    )
    SELECT 
        R.RelationDataID,
        
        -- Source Identity
		R.SourceNodeID,
        R.SourceGroupNodeID,
        R.SourceNodeValueID,
		R.SourceNodeColor,
        
        -- Target Identity
		R.TargetNodeID,
        R.TargetGroupNodeID,
        R.TargetNodeValueID,
        
        -- Display Info
        CASE WHEN @Lang = 'ar-AE' THEN R.TargetNodeValueAr ELSE R.TargetNodeValueEn END AS TargetNodeValue,
        R.TargetNodeColor,
        
        R.TargetNodeValueDate,
        CASE WHEN @Lang = 'ar-AE' THEN R.RelationAr ELSE R.RelationEn END AS Relation
    FROM RankedRelations R
    WHERE RowNum <= @MaxNeighbors;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesFindPath]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_NodesFindPath]
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
/****** Object:  StoredProcedure [graphdb].[sp_NodesGenerate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_NodesGenerate]
  @PruneMissing BIT = 1     -- currently only used for ViewColumns pruning
AS
/*
EXEC [graphdb].[sp_NodesGenerate];
*/
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRAN;

    ----------------------------------------------------------------
    -- 1. Collect all registered views with their object_id
    ----------------------------------------------------------------
    DECLARE @V TABLE (
        ViewID INT NOT NULL,
        oid    INT NOT NULL
    );

    INSERT @V (ViewID, oid)
    SELECT
        v.ViewID,
        OBJECT_ID(QUOTENAME(v.ViewDB) + N'.' + QUOTENAME(v.ViewSchema) + N'.' + QUOTENAME(v.ViewName))
    FROM graphdb.Views AS v
    WHERE v.ViewName IS NOT NULL;

    ----------------------------------------------------------------
    -- 2. Get all ID_*_ID columns across all registered views
    --    (for Nodes)
    ----------------------------------------------------------------
    ;WITH C AS (
      SELECT DISTINCT
          c.name AS ColumnID
      FROM @V v
      JOIN sys.columns c
        ON c.object_id = v.oid
      WHERE c.name LIKE N'ID\_%\_ID' ESCAPE N'\'   -- pattern: ID_*_ID
    )
    SELECT ColumnID
    INTO #All
    FROM C;

    ----------------------------------------------------------------
    -- 3. Insert new Nodes for missing ColumnID
    ----------------------------------------------------------------
    INSERT INTO graphdb.Nodes (ColumnID)
    SELECT a.ColumnID
    FROM #All a
    LEFT JOIN graphdb.Nodes s
      ON s.ColumnID = a.ColumnID
    WHERE s.ColumnID IS NULL;

    ----------------------------------------------------------------
    -- 4. (Node pruning REMOVED to avoid FK conflicts with Relations)
    --    If you want safe pruning later, it must also check that
    --    no Relations rows reference a given NodeID.
    ----------------------------------------------------------------
    -- IF @PruneMissing = 1
    -- BEGIN
    --   DELETE s
    --   FROM graphdb.Nodes s
    --   LEFT JOIN #All a
    --     ON a.ColumnID = s.ColumnID
    --   WHERE a.ColumnID IS NULL;
    -- END

    ----------------------------------------------------------------
    -- 5. Build all (ViewID, ColumnID) pairs from actual views
    --    (for ViewColumns sync)
    ----------------------------------------------------------------
    ;WITH VC AS (
      SELECT DISTINCT
          v.ViewID,
          c.name AS ColumnID
      FROM @V v
      JOIN sys.columns c
        ON c.object_id = v.oid
      WHERE c.name LIKE N'ID\_%\_ID' ESCAPE N'\'
    )
    SELECT ViewID, ColumnID
    INTO #AllViewColumns
    FROM VC;

    ----------------------------------------------------------------
    -- 6. Insert missing rows into graphdb.ViewColumns
    ----------------------------------------------------------------
    INSERT INTO graphdb.ViewColumns (ViewID, ColumnID)
    SELECT a.ViewID, a.ColumnID
    FROM #AllViewColumns a
    LEFT JOIN graphdb.ViewColumns vc
      ON vc.ViewID   = a.ViewID
     AND vc.ColumnID = a.ColumnID
    WHERE vc.ViewColumnID IS NULL;   -- only new pairs

    ----------------------------------------------------------------
    -- 7. Delete rows from graphdb.ViewColumns that no longer exist
    ----------------------------------------------------------------
    IF @PruneMissing = 1
    BEGIN
      DELETE vc
      FROM graphdb.ViewColumns vc
      LEFT JOIN #AllViewColumns a
        ON a.ViewID   = vc.ViewID
       AND a.ColumnID = vc.ColumnID
      WHERE a.ViewID IS NULL;        -- pair no longer valid
    END

    ----------------------------------------------------------------
    -- 8. Commit
    ----------------------------------------------------------------
    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK;

    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesSearch]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_NodesSearch]
    @Lang NVARCHAR(10) = N'en-US',              -- 'en-US' or 'ar-AE'
    @NodeIdentities [graphdb].[NodeIdentityTable] READONLY  -- TVP with GroupNodeID + NodeValueID
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT distinct ND.[GroupNodeID],
            ND.[NodeValueID],
            CASE 
                WHEN @Lang = N'en-US' THEN ND.[NodeValueEn]
                ELSE ND.[NodeValueAr]
            END AS [NodeValue]
        FROM [graphdb].[vNodeData]  ND
        INNER JOIN @NodeIdentities T ON T.[GroupNodeID] = ND.[GroupNodeID] AND T.[NodeValueID] = ND.[NodeValueID]
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodeUpdate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_NodeUpdate]
(
    @NodeID        INT,
    @GroupNodeID   INT        = NULL,
    @ColumnEn      NVARCHAR(200) = NULL,
    @ColumnAr      NVARCHAR(200) = NULL,
    @ColumnColor   NVARCHAR(50)  = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update only the columns provided (NULLs will not overwrite)
    UPDATE n
    SET 
        GroupNodeID = COALESCE(@GroupNodeID, GroupNodeID),
        ColumnEn    = COALESCE(@ColumnEn, ColumnEn),
        ColumnAr    = COALESCE(@ColumnAr, ColumnAr),
        ColumnColor = COALESCE(@ColumnColor, ColumnColor)
    FROM [graphdb].[Nodes] AS n
    WHERE n.NodeID = @NodeID;

END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_RelationDataGenerate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*========================================================
  [graphdb].[sp_RelationDataGenerate]

  Purpose:
    Populate [graphdb].[RelationData] as simple edges:

        ViewGroupID,
        SourceNodeDataID,
        TargetNodeDataID,
        RelationEn,
        RelationAr,
        RelationValueDate

    from:

      - graphdb.Relations         (metadata of triples)
      - graphdb.ViewGroups
      - graphdb.ViewGroupLists
      - graphdb.Views
      - graphdb.ViewColumns
      - graphdb.Nodes
      - graphdb.NodeData
      - underlying data views (IncidentsData, RelationsData, ...)

  Relation label rules:
    - If Relations.RelationNodeID IS NOT NULL:
        → Treat it as a flag: get RelationEn/RelationAr from
          ENED_*_ENED / ARED_*_ARED columns of the data view corresponding
          to that Node (using its ColumnID pattern ID_X_ID → ENED_X_ENED).
    - ELSE:
        → Use Relations.RelationEn / Relations.RelationAr as constants
          for all edges from that relation.

    Nulls are allowed – RelationEn/Ar can end up NULL.

  Usage:
    EXEC graphdb.sp_RelationDataGenerate;               -- all ViewGroups
    EXEC graphdb.sp_RelationDataGenerate @ViewGroupID=1;
=========================================================*/
CREATE   PROCEDURE [graphdb].[sp_RelationDataGenerate]
    @ViewGroupID INT = NULL      -- NULL = all groups
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------------
        -- 0. Temp table describing, for each relation + view:
        --    - which columns to use for Source / Target IDs
        --    - which ENED/ARED columns to use for relation label (if any)
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#RelSources') IS NOT NULL DROP TABLE #RelSources;

        CREATE TABLE #RelSources
        (
            ViewGroupID       INT,
            RelationID        INT,
            ViewID            INT,
            ViewDB            NVARCHAR(128),
            ViewSchema        NVARCHAR(128),
            ViewNameEn        NVARCHAR(128),

            SourceNodeID      INT,
            TargetNodeID      INT,       -- from DisplayNodeID

            SourceIdCol       SYSNAME,
            TargetIdCol       SYSNAME,
            SourceDateCol     SYSNAME,

            HasRelationNode   BIT,
            RelEnCol          SYSNAME NULL,   -- ENED_*_ENED
            RelArCol          SYSNAME NULL,   -- ARED_*_ARED

            RelationEnDefault NVARCHAR(128) NULL,  -- from graphdb.Relations
            RelationArDefault NVARCHAR(128) NULL
        );

        ------------------------------------------------------------
        -- 1. Build the mapping metadata
        ------------------------------------------------------------
        ;WITH ActiveRel AS (
            SELECT
                r.RelationID,
                r.ViewGroupID,
                r.SourceNodeID,
                r.SearchNodeID,
                r.DisplayNodeID,
                r.RelationNodeID,
                r.RelationEn,
                r.RelationAr
            FROM graphdb.Relations r
            WHERE r.isActive = 1
              AND (@ViewGroupID IS NULL OR r.ViewGroupID = @ViewGroupID)
        ),
        VGViews AS (
            SELECT
                vgl.ViewGroupID,
                v.ViewID,
                v.ViewDB,
                v.ViewSchema,
                v.ViewName
            FROM graphdb.ViewGroupLists vgl
            JOIN graphdb.Views v
              ON v.ViewID = vgl.ViewID
        ),
        ViewNodeCols AS (
            SELECT
                vgv.ViewGroupID,
                vgv.ViewID,
                vgv.ViewDB,
                vgv.ViewSchema,
                vgv.ViewName,
                n.NodeID,
                vc.ColumnID                -- e.g. ID_A_ID
            FROM VGViews vgv
            JOIN graphdb.ViewColumns vc
              ON vc.ViewID = vgv.ViewID
            JOIN graphdb.Nodes n
              ON n.ColumnID = vc.ColumnID
        ),
        -- For RelationNodeID, we also need ENED/ARED columns from its ColumnID
        RelCols AS (
            SELECT
                vnc.ViewGroupID,
                vnc.ViewID,
                vnc.NodeID,
                vnc.ColumnID,
                -- Extract X from ID_X_ID
                MiddleKey  = SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6),
                EnColName  = N'ENED_' + SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6) + N'_ENED',
                ArColName  = N'ARED_' + SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6) + N'_ARED'
            FROM ViewNodeCols vnc
        )
        INSERT INTO #RelSources (
            ViewGroupID, RelationID, ViewID, ViewDB, ViewSchema, ViewNameEn,
            SourceNodeID, TargetNodeID,
            SourceIdCol, TargetIdCol, SourceDateCol,
            HasRelationNode, RelEnCol, RelArCol,
            RelationEnDefault, RelationArDefault
        )
        SELECT
            ar.ViewGroupID,
            ar.RelationID,
            vgv.ViewID,
            vgv.ViewDB,
            vgv.ViewSchema,
            vgv.ViewName,

            ar.SourceNodeID,
            ar.DisplayNodeID,

            src.ColumnID                                AS SourceIdCol,
            tgt.ColumnID                                AS TargetIdCol,
            -- source DATE column from source ID_*_ID
            SourceDateCol = N'DATE_' + SUBSTRING(src.ColumnID, 4, LEN(src.ColumnID) - 6) + N'_DATE',

            HasRelationNode   = CASE WHEN ar.RelationNodeID IS NOT NULL THEN 1 ELSE 0 END,
            RelEnCol          = rc.EnColName,
            RelArCol          = rc.ArColName,

            RelationEnDefault = ar.RelationEn,
            RelationArDefault = ar.RelationAr
        FROM ActiveRel ar
        JOIN VGViews vgv
          ON vgv.ViewGroupID = ar.ViewGroupID
        -- We require that the View has both Source and Target nodes
        JOIN ViewNodeCols src
          ON src.ViewID = vgv.ViewID AND src.NodeID = ar.SourceNodeID
        JOIN ViewNodeCols tgt
          ON tgt.ViewID = vgv.ViewID AND tgt.NodeID = ar.DisplayNodeID
        LEFT JOIN RelCols rc
          ON rc.ViewID  = vgv.ViewID AND rc.NodeID = ar.RelationNodeID;

        ------------------------------------------------------------
        -- 2. Build RelationData rows for each mapping row
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#RelationDataNew') IS NOT NULL DROP TABLE #RelationDataNew;

        CREATE TABLE #RelationDataNew
        (
            ViewGroupID         INT,
            SourceNodeDataID    BIGINT,
            TargetNodeDataID    BIGINT,
            RelationEn          NVARCHAR(128) NULL,
            RelationAr          NVARCHAR(128) NULL,
            RelationValueDate   DATE NULL
        );

        DECLARE
            @VGID        INT,
            @RelID       INT,
            @ViewID      INT,
            @ViewDB      NVARCHAR(128),
            @ViewSchema  NVARCHAR(128),
            @ViewName    NVARCHAR(128),

            @SourceNodeID   INT,
            @TargetNodeID   INT,

            @SourceIdCol    SYSNAME,
            @TargetIdCol    SYSNAME,
            @SourceDateCol  SYSNAME,

            @HasRelNode     BIT,
            @RelEnCol       SYSNAME,
            @RelArCol       SYSNAME,

            @RelEnDefault   NVARCHAR(128),
            @RelArDefault   NVARCHAR(128),

            @sql            NVARCHAR(MAX),
            @RelEnLit       NVARCHAR(MAX),
            @RelArLit       NVARCHAR(MAX);

        DECLARE curRel CURSOR LOCAL FAST_FORWARD FOR
            SELECT
                ViewGroupID, RelationID, ViewID, ViewDB, ViewSchema, ViewNameEn,
                SourceNodeID, TargetNodeID,
                SourceIdCol, TargetIdCol, SourceDateCol,
                HasRelationNode, RelEnCol, RelArCol,
                RelationEnDefault, RelationArDefault
            FROM #RelSources;

        OPEN curRel;
        FETCH NEXT FROM curRel INTO
            @VGID, @RelID, @ViewID, @ViewDB, @ViewSchema, @ViewName,
            @SourceNodeID, @TargetNodeID,
            @SourceIdCol, @TargetIdCol, @SourceDateCol,
            @HasRelNode, @RelEnCol, @RelArCol,
            @RelEnDefault, @RelArDefault;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            ------------------------------------------------------------
            -- Prepare literals for default relation text (if no RelNode)
            ------------------------------------------------------------
            IF @RelEnDefault IS NULL
                SET @RelEnLit = N'NULL';
            ELSE
                SET @RelEnLit = N'N''' + REPLACE(@RelEnDefault, N'''', N'''''') + N'''';

            IF @RelArDefault IS NULL
                SET @RelArLit = N'NULL';
            ELSE
                SET @RelArLit = N'N''' + REPLACE(@RelArDefault, N'''', N'''''') + N'''';

            ------------------------------------------------------------
            -- Build dynamic SQL for this (ViewGroup, Relation, View)
            ------------------------------------------------------------
            SET @sql = N'
                INSERT INTO #RelationDataNew
                    (ViewGroupID,
                     SourceNodeDataID,
                     TargetNodeDataID,
                     RelationEn,
                     RelationAr,
                     RelationValueDate)
                SELECT
                    ' + CAST(@VGID AS NVARCHAR(20)) + N' AS ViewGroupID,
                    nd_src.NodeDataID AS SourceNodeDataID,
                    nd_tgt.NodeDataID AS TargetNodeDataID,'

                + CASE 
                    WHEN @HasRelNode = 1 AND @RelEnCol IS NOT NULL THEN
                        N' t.' + QUOTENAME(@RelEnCol) + N' AS RelationEn,'
                    ELSE
                        N' ' + @RelEnLit + N' AS RelationEn,'
                  END
                + CASE 
                    WHEN @HasRelNode = 1 AND @RelArCol IS NOT NULL THEN
                        N' t.' + QUOTENAME(@RelArCol) + N' AS RelationAr,'
                    ELSE
                        N' ' + @RelArLit + N' AS RelationAr,'
                  END
                + N'
                    t.' + QUOTENAME(@SourceDateCol) + N' AS RelationValueDate
                FROM ' + QUOTENAME(@ViewDB) + N'.' + QUOTENAME(@ViewSchema) + N'.' + QUOTENAME(@ViewName) + N' AS t
                JOIN graphdb.NodeData nd_src
                  ON nd_src.ViewGroupID = ' + CAST(@VGID AS NVARCHAR(20)) + N'
                 AND nd_src.NodeID      = ' + CAST(@SourceNodeID AS NVARCHAR(20)) + N'
                 AND nd_src.NodeValueID = CONVERT(NVARCHAR(128), t.' + QUOTENAME(@SourceIdCol) + N')
                JOIN graphdb.NodeData nd_tgt
                  ON nd_tgt.ViewGroupID = ' + CAST(@VGID AS NVARCHAR(20)) + N'
                 AND nd_tgt.NodeID      = ' + CAST(@TargetNodeID AS NVARCHAR(20)) + N'
                 AND nd_tgt.NodeValueID = CONVERT(NVARCHAR(128), t.' + QUOTENAME(@TargetIdCol) + N')
                WHERE t.' + QUOTENAME(@SourceIdCol) + N' IS NOT NULL
                  AND t.' + QUOTENAME(@TargetIdCol) + N' IS NOT NULL;
            ';

            --PRINT @sql; -- for debugging
            EXEC sys.sp_executesql @sql;

            FETCH NEXT FROM curRel INTO
                @VGID, @RelID, @ViewID, @ViewDB, @ViewSchema, @ViewName,
                @SourceNodeID, @TargetNodeID,
                @SourceIdCol, @TargetIdCol, @SourceDateCol,
                @HasRelNode, @RelEnCol, @RelArCol,
                @RelEnDefault, @RelArDefault;
        END

        CLOSE curRel;
        DEALLOCATE curRel;

        ------------------------------------------------------------
        -- 3. Optional dedup of #RelationDataNew (same edge produced twice)
        ------------------------------------------------------------
        ;WITH Dedup AS (
            SELECT
                ViewGroupID,
                SourceNodeDataID,
                TargetNodeDataID,
                RelationEn,
                RelationAr,
                RelationValueDate,
                ROW_NUMBER() OVER (
                    PARTITION BY ViewGroupID, SourceNodeDataID, TargetNodeDataID,
                                 RelationEn, RelationAr, RelationValueDate
                    ORDER BY (SELECT 0)
                ) AS rn
            FROM #RelationDataNew
        )
        DELETE FROM Dedup WHERE rn > 1;

        ------------------------------------------------------------
        -- 4. Upsert into graphdb.RelationData
        --    (simple: we'll clear and reload per ViewGroup for now)
        ------------------------------------------------------------
        IF @ViewGroupID IS NULL
        BEGIN
            DELETE FROM graphdb.RelationData;
        END
        ELSE
        BEGIN
            DELETE FROM graphdb.RelationData
            WHERE ViewGroupID = @ViewGroupID;
        END

        INSERT INTO graphdb.RelationData
            (ViewGroupID, SourceNodeDataID, TargetNodeDataID, RelationEn, RelationAr, RelationValueDate)
        SELECT
            ViewGroupID, SourceNodeDataID, TargetNodeDataID, RelationEn, RelationAr, RelationValueDate
        FROM #RelationDataNew;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;

        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_RelationsGenerate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*========================================================
  [graphdb].[sp_RelationsGenerate]

  New rules:

    - Work per ViewGroupID (from ViewGroups / ViewGroupLists / Views / ViewColumns / Nodes).
    - Only generate (SourceNodeID, SearchNodeID) pairs where:
          Nodes share the SAME GroupNodeID.
          → "A has to search its own type"
          → "A can search its own B (where A and B have same GroupNodeID)"
    - For each such (Source, Search), generate DisplayNodeID from all nodes
      in the same ViewGroup.
    - EXCLUDE triples where:
          SourceNodeID = SearchNodeID = DisplayNodeID
      → "A cannot search A to display A".

    - Insert only NEW triples into [graphdb].[Relations].
    - Do NOT touch RelationNodeID / RelationEn / RelationAr / isActive.
    - Optionally prune triples no longer valid.

  Example:
    EXEC [graphdb].[sp_RelationsGenerate];       -- with pruning
    EXEC [graphdb].[sp_RelationsGenerate] 0;     -- without pruning
=========================================================*/
CREATE   PROCEDURE [graphdb].[sp_RelationsGenerate]
  @PruneMissing BIT = 1   -- 1 = delete rows whose (ViewGroup,Source,Search,Display) triple no longer exists
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRAN;

    ------------------------------------------------------------
    -- 1. For each ViewGroup, find all participating NodeIDs
    --    via ViewGroupLists + Views + ViewColumns + Nodes(ColumnID)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#VGNodes') IS NOT NULL DROP TABLE #VGNodes;

    CREATE TABLE #VGNodes
    (
        ViewGroupID INT NOT NULL,
        NodeID      INT NOT NULL,
        GroupNodeID INT NULL
    );

    INSERT INTO #VGNodes (ViewGroupID, NodeID, GroupNodeID)
    SELECT DISTINCT
        vgl.ViewGroupID,
        n.NodeID,
        n.GroupNodeID
    FROM graphdb.ViewGroupLists  AS vgl
    JOIN graphdb.Views           AS v   ON v.ViewID   = vgl.ViewID
    JOIN graphdb.ViewColumns     AS vc  ON vc.ViewID  = v.ViewID
    JOIN graphdb.Nodes           AS n   ON n.ColumnID = vc.ColumnID;

    ------------------------------------------------------------
    -- 2. Build (SourceNodeID, SearchNodeID) pairs:
    --    - same ViewGroup
    --    - same GroupNodeID
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#SrcSearch') IS NOT NULL DROP TABLE #SrcSearch;

    CREATE TABLE #SrcSearch
    (
        ViewGroupID   INT NOT NULL,
        SourceNodeID  INT NOT NULL,
        SearchNodeID  INT NOT NULL
    );

    INSERT INTO #SrcSearch (ViewGroupID, SourceNodeID, SearchNodeID)
    SELECT
        s.ViewGroupID,
        s.NodeID  AS SourceNodeID,
        se.NodeID AS SearchNodeID
    FROM #VGNodes AS s
    JOIN #VGNodes AS se
      ON se.ViewGroupID = s.ViewGroupID
     AND se.GroupNodeID = s.GroupNodeID;   -- same type (GroupNodeID)

    ------------------------------------------------------------
    -- 3. Combine with all DisplayNodeID in that ViewGroup,
    --    and remove the "A searches A to display A" triple.
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#AllRelations') IS NOT NULL DROP TABLE #AllRelations;

    SELECT DISTINCT
        ss.ViewGroupID,
        ss.SourceNodeID,
        ss.SearchNodeID,
        d.NodeID AS DisplayNodeID
    INTO #AllRelations
    FROM #SrcSearch ss
    JOIN #VGNodes d
      ON d.ViewGroupID = ss.ViewGroupID
    WHERE NOT (
        ss.SourceNodeID  = ss.SearchNodeID
        AND ss.SearchNodeID = d.NodeID     -- i.e. Source = Search = Display
    );

    ------------------------------------------------------------
    -- 4. Insert NEW triples into graphdb.Relations
    ------------------------------------------------------------
    INSERT INTO graphdb.Relations (ViewGroupID, SourceNodeID, SearchNodeID, DisplayNodeID)
    SELECT a.ViewGroupID, a.SourceNodeID, a.SearchNodeID, a.DisplayNodeID
    FROM #AllRelations a
    LEFT JOIN graphdb.Relations r
      ON  r.ViewGroupID    = a.ViewGroupID
      AND r.SourceNodeID   = a.SourceNodeID
      AND r.SearchNodeID   = a.SearchNodeID
      AND r.DisplayNodeID  = a.DisplayNodeID
    WHERE r.RelationID IS NULL;    -- only missing ones

    ------------------------------------------------------------
    -- 5. Optionally DELETE relations whose triple no longer exists
    ------------------------------------------------------------
    IF @PruneMissing = 1
    BEGIN
      DELETE r
      FROM graphdb.Relations r
      LEFT JOIN #AllRelations a
        ON  a.ViewGroupID    = r.ViewGroupID
        AND a.SourceNodeID   = r.SourceNodeID
        AND a.SearchNodeID   = r.SearchNodeID
        AND a.DisplayNodeID  = r.DisplayNodeID
      WHERE a.ViewGroupID IS NULL;   -- triple no longer valid
    END;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK;

    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_RelationsList]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_RelationsList]
    @ViewGroupID INT,
    @OnlyActive  BIT = 0,                 -- 1 = only active
    @Lang        NVARCHAR(10) = N'en-US'  -- 'en-US' or 'ar-AE'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP (1000)
              v.[RelationID]
            , v.[ViewGroupID]
            , v.[SourceNodeID]
            , v.[SearchNodeID]
            , v.[DisplayNodeID]
            , v.[RelationNodeID]
            , v.[RelationEn]
            , v.[RelationAr]
            , v.[isActive]

            -- Localized names via CASE
            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[SourceColumnAr]
                ELSE v.[SourceColumnEn]
              END AS [SourceColumnName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[SourceGroupAr]
                ELSE v.[SourceGroupEn]
              END AS [SourceGroupName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[SearchColumnAr]
                ELSE v.[SearchColumnEn]
              END AS [SearchColumnName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[SearchGroupAr]
                ELSE v.[SearchGroupEn]
              END AS [SearchGroupName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[DisplayColumnAr]
                ELSE v.[DisplayColumnEn]
              END AS [DisplayColumnName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[DisplayGroupAr]
                ELSE v.[DisplayGroupEn]
              END AS [DisplayGroupName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[RelationColumnAr]
                ELSE v.[RelationColumnEn]
              END AS [RelationColumnName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[RelationGroupAr]
                ELSE v.[RelationGroupEn]
              END AS [RelationGroupName]

            , CASE 
                WHEN LOWER(@Lang) = N'ar-ae' THEN v.[RelationAr]
                ELSE v.[RelationEn]
              END AS [RelationText]

        FROM [graphdb].[vRelations] AS v
        WHERE
            (@ViewGroupID IS NULL OR v.[ViewGroupID] = @ViewGroupID)
            AND (@OnlyActive = 0 OR v.[isActive] = 1)
        ORDER BY
            v.[ViewGroupID],

            -- Group by unordered pair (Source, Display)
            CASE 
                WHEN v.SourceNodeID <= v.DisplayNodeID 
                    THEN v.SourceNodeID 
                    ELSE v.DisplayNodeID 
            END,   -- PairMin

            CASE 
                WHEN v.SourceNodeID <= v.DisplayNodeID 
                    THEN v.DisplayNodeID 
                    ELSE v.SourceNodeID 
            END,   -- PairMax

            -- Within each pair: first Source→Display, then Display→Source
            CASE 
                WHEN v.SourceNodeID <= v.DisplayNodeID 
                    THEN 1 
                    ELSE 2 
            END,

            v.[RelationID];  -- stable tie-breaker
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_RelationUpdate]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_RelationUpdate]
    @RelationID     INT,                 -- must be existing ID
    @RelationNodeID INT = NULL,
    @RelationEn     NVARCHAR(128) = NULL,
    @RelationAr     NVARCHAR(128) = NULL,
    @IsActive       BIT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        --------------------------------------------------------
        -- Basic ID check
        --------------------------------------------------------
        IF @RelationID IS NULL OR @RelationID <= 0
        BEGIN
            RAISERROR(N'RelationID must be a valid existing ID for update.', 16, 1);
            RETURN;
        END

        --------------------------------------------------------
        -- Normalize / trim text
        --------------------------------------------------------
        SET @RelationEn = NULLIF(LTRIM(RTRIM(@RelationEn)), N'');
        SET @RelationAr = NULLIF(LTRIM(RTRIM(@RelationAr)), N'');

        --------------------------------------------------------
        -- Validation rules:
        --  1) If @RelationNodeID IS NULL =>
        --       both @RelationEn AND @RelationAr must have values.
        --  2) If @RelationEn/@RelationAr have values =>
        --       @RelationNodeID must be NULL (mutually exclusive).
        --------------------------------------------------------

        IF @RelationNodeID IS NULL
        BEGIN
            -- Need both texts
            IF @RelationEn IS NULL OR @RelationAr IS NULL
            BEGIN
                RAISERROR(
                    N'When RelationNodeID is NULL, both RelationEn and RelationAr must have values.',
                    16, 1
                );
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- NodeID supplied → text must NOT be supplied
            IF @RelationEn IS NOT NULL OR @RelationAr IS NOT NULL
            BEGIN
                RAISERROR(
                    N'When RelationNodeID is provided, RelationEn and RelationAr must be NULL.',
                    16, 1
                );
                RETURN;
            END
        END

        --------------------------------------------------------
        -- Perform the update
        --------------------------------------------------------
        UPDATE r
        SET
            r.[RelationNodeID] = @RelationNodeID,
            r.[RelationEn]     = @RelationEn,
            r.[RelationAr]     = @RelationAr,
            r.[isActive]       = @IsActive
        FROM [graphdb].[Relations] r
        WHERE r.[RelationID] = @RelationID;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(N'RelationID %d not found for update.', 16, 1, @RelationID);
        END
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_ViewGroupNodesList]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_ViewGroupNodesList]
    @ViewGroupID INT,
    @Lang        NVARCHAR(10) = N'en-US'   -- 'en-US' or 'ar-AE'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT DISTINCT
            n.NodeID,
            n.GroupNodeID,

            -- Group node name by language
            CASE 
                WHEN @Lang = N'ar-AE' THEN gn.GroupNodeAr
                ELSE gn.GroupNodeEn
            END AS GroupNodeName,

            n.ColumnID,
			n.ColumnAr,
			n.ColumnEn,
            -- Node (column) name by language
            CASE 
                WHEN @Lang = N'ar-AE' THEN n.ColumnAr
                ELSE n.ColumnEn
            END AS NodeName,

            n.ColumnColor
        FROM graphdb.ViewGroupLists AS vgl
        JOIN graphdb.Views         AS v   ON v.ViewID     = vgl.ViewID
        JOIN graphdb.ViewColumns   AS vc  ON vc.ViewID    = v.ViewID
        JOIN graphdb.Nodes         AS n   ON n.ColumnID   = vc.ColumnID
        LEFT JOIN graphdb.GroupNode AS gn ON gn.GroupNodeID = n.GroupNodeID
        WHERE vgl.ViewGroupID = @ViewGroupID
        ORDER BY
            GroupNodeName,
            NodeName;
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_ViewGroupsList]    Script Date: 12/4/2025 7:17:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_ViewGroupsList]
    @Lang NVARCHAR(10) = 'en-US'   -- Only 'en-US' or 'ar-AE'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP (1000)
            vg.[ViewGroupID],
            CASE 
                WHEN @Lang = N'ar-AE' THEN vg.[ViewGroupNameAr]
                ELSE vg.[ViewGroupNameEn]
            END AS [ViewGroupName],
            @Lang AS [Lang]
        FROM [graphdb].[ViewGroups] AS vg
        ORDER BY vg.[ViewGroupID];
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "nd"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 249
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "n"
            Begin Extent = 
               Top = 7
               Left = 297
               Bottom = 170
               Right = 491
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "g"
            Begin Extent = 
               Top = 7
               Left = 539
               Bottom = 148
               Right = 733
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'graphdb', @level1type=N'VIEW',@level1name=N'vNodeData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'graphdb', @level1type=N'VIEW',@level1name=N'vNodeData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "RD"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 272
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "SND"
            Begin Extent = 
               Top = 7
               Left = 320
               Bottom = 170
               Right = 521
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "TND"
            Begin Extent = 
               Top = 7
               Left = 569
               Bottom = 170
               Right = 770
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'graphdb', @level1type=N'VIEW',@level1name=N'vRelationData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'graphdb', @level1type=N'VIEW',@level1name=N'vRelationData'
GO
