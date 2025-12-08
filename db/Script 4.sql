USE [IAS]
GO
/****** Object:  Schema [graphdb]    Script Date: 09/12/2025 12:35:44 AM ******/
CREATE SCHEMA [graphdb]
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeDataIDTable]    Script Date: 09/12/2025 12:35:44 AM ******/
CREATE TYPE [graphdb].[NodeDataIDTable] AS TABLE(
	[NodeDataID] [bigint] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[NodeDataID] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeFilterTable]    Script Date: 09/12/2025 12:35:44 AM ******/
CREATE TYPE [graphdb].[NodeFilterTable] AS TABLE(
	[NodeID] [int] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [graphdb].[NodeIdentityTable]    Script Date: 09/12/2025 12:35:44 AM ******/
CREATE TYPE [graphdb].[NodeIdentityTable] AS TABLE(
	[GroupNodeID] [int] NOT NULL,
	[NodeValueID] [nvarchar](128) NOT NULL
)
GO
/****** Object:  Table [graphdb].[Relations]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[Nodes]    Script Date: 09/12/2025 12:35:44 AM ******/
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
	[isDefaultSearch] [bit] NOT NULL,
	[SearchMonths] [int] NOT NULL,
 CONSTRAINT [PK_SeedColumnCatalog] PRIMARY KEY CLUSTERED 
(
	[NodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[GroupNode]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  View [graphdb].[vRelations]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[NodeData]    Script Date: 09/12/2025 12:35:44 AM ******/
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
	[NodeValueDate] [date] NOT NULL,
	[isActive] [bit] NOT NULL,
 CONSTRAINT [PK_NodeData] PRIMARY KEY CLUSTERED 
(
	[NodeDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_NodeData] UNIQUE NONCLUSTERED 
(
	[ViewGroupID] ASC,
	[NodeID] ASC,
	[NodeValueID] ASC,
	[NodeValueDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [graphdb].[vNodeData]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[RelationData]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  View [graphdb].[vRelationData]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[IncidentsData]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[IncidentsData](
	[ENED_A_ENED] [varchar](50) NULL,
	[ARED_A_ARED] [varchar](50) NULL,
	[DATE_A_DATE] [date] NULL,
	[ID_A_ID] [int] NULL,
	[ENTEXT_A_ENTEXT] [varchar](100) NULL,
	[ARTEXT_A_ARTEXT] [varchar](100) NULL,
	[ENED_B_ENED] [varchar](50) NULL,
	[ARED_B_ARED] [varchar](50) NULL,
	[DATE_B_DATE] [date] NULL,
	[ID_B_ID] [int] NULL,
	[ENTEXT_B_ENTEXT] [varchar](100) NULL,
	[ARTEXT_B_ARTEXT] [varchar](100) NULL,
	[ENED_C_ENED] [varchar](50) NULL,
	[ARED_C_ARED] [varchar](50) NULL,
	[DATE_C_DATE] [date] NULL,
	[ID_C_ID] [int] NULL,
	[ENTEXT_C_ENTEXT] [varchar](100) NULL,
	[ARTEXT_C_ARTEXT] [varchar](100) NULL,
	[ENED_D_ENED] [varchar](50) NULL,
	[ARED_D_ARED] [varchar](50) NULL,
	[DATE_D_DATE] [date] NULL,
	[ID_D_ID] [int] NULL,
	[ENTEXT_D_ENTEXT] [varchar](100) NULL,
	[ARTEXT_D_ARTEXT] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[RelationsData]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[RelationsData](
	[ENED_B_ENED] [varchar](50) NULL,
	[ARED_B_ARED] [varchar](50) NULL,
	[DATE_B_DATE] [date] NULL,
	[ID_B_ID] [int] NULL,
	[ENTEXT_B_ENTEXT] [varchar](100) NULL,
	[ARTEXT_B_ARTEXT] [varchar](100) NULL,
	[ENED_R_ENED] [varchar](50) NULL,
	[ARED_R_ARED] [varchar](50) NULL,
	[DATE_R_DATE] [date] NULL,
	[ID_R_ID] [int] NULL,
	[ENTEXT_R_ENTEXT] [varchar](100) NULL,
	[ARTEXT_R_ARTEXT] [varchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[ViewColumns]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[ViewGroupLists]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  Table [graphdb].[ViewGroups]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [graphdb].[ViewGroups](
	[ViewGroupID] [int] IDENTITY(1,1) NOT NULL,
	[ViewGroupNameEn] [nvarchar](200) NOT NULL,
	[ViewGroupNameAr] [nvarchar](200) NOT NULL,
	[DataProcessedDate] [datetime] NULL,
 CONSTRAINT [PK_ViewGroups] PRIMARY KEY CLUSTERED 
(
	[ViewGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [graphdb].[Views]    Script Date: 09/12/2025 12:35:44 AM ******/
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
ALTER TABLE [graphdb].[NodeData] ADD  CONSTRAINT [DF_NodeData_NodeValueDate]  DEFAULT (CONVERT([date],'01-Jan-1990')) FOR [NodeValueDate]
GO
ALTER TABLE [graphdb].[NodeData] ADD  CONSTRAINT [DF_NodeData_isActive]  DEFAULT ((1)) FOR [isActive]
GO
ALTER TABLE [graphdb].[Nodes] ADD  CONSTRAINT [DF_Nodes_ColumnColor]  DEFAULT (N'#b3ffff') FOR [ColumnColor]
GO
ALTER TABLE [graphdb].[Nodes] ADD  CONSTRAINT [DF_Nodes_isDefaultSearch]  DEFAULT ((1)) FOR [isDefaultSearch]
GO
ALTER TABLE [graphdb].[Nodes] ADD  CONSTRAINT [DF_Nodes_SearchMonths]  DEFAULT ((6)) FOR [SearchMonths]
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
/****** Object:  StoredProcedure [graphdb].[sp_GraphDataGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [graphdb].[sp_GraphDataGenerate]
   @ViewGroupID INT = NULL
AS
/*
EXEC [graphdb].[sp_GraphDataGenerate]
*/
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRAN;

    EXEC [graphdb].[sp_NodeDataGenerate] @ViewGroupID=@ViewGroupID;

    EXEC [graphdb].[sp_RelationDataGenerate] @ViewGroupID=@ViewGroupID;

	UPDATE [graphdb].[ViewGroups]
	SET [DataProcessedDate] = GETDATE()
	WHERE @ViewGroupID IS NULL OR [ViewGroupID] = @ViewGroupID;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_GraphSchemaGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_GraphSchemaGenerate]
  @PruneMissing BIT = 1
AS
/*
EXEC [graphdb].[sp_GraphSchemaGenerate]
*/
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRAN;

    -- 1️⃣ Generate/update Nodes and ViewColumns
    EXEC [graphdb].[sp_NodesGenerate] @PruneMissing;

	PRINT ('Node Generated.')
    -- 2️⃣ Generate/update Relations per ViewGroup
    EXEC [graphdb].[sp_RelationsGenerate] @PruneMissing;

	PRINT ('Relations Generated.')

    COMMIT;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
	PRINT(@msg)
    RAISERROR(@msg, 16, 1);
  END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_GroupNodeList]    Script Date: 09/12/2025 12:35:44 AM ******/
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
            WHEN @Lang = N'ar-AE' THEN GroupNodeAr
            ELSE GroupNodeEn
        END AS GroupNodeName
    FROM [graphdb].[GroupNode]
    ORDER BY 
        CASE 
            WHEN @Lang = N'ar-AE' THEN GroupNodeAr
            ELSE GroupNodeEn
        END;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodeDataAutoComplete]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  StoredProcedure [graphdb].[sp_NodeDataGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************************
  Procedure: [graphdb].[sp_NodeDataGenerate]
  PURPOSE
  ------------------------------------------------------------------------------------------
  Populate and maintain [graphdb].[NodeData] with unique 
  (ViewGroupID, NodeID, NodeValueID, NodeValueDate) keys.

  RULES
  ------------------------------------------------------------------------------------------
  1) Insert/update NodeData with values coming from ViewGroup-linked sources.
  2) NodeValueDate must have a default if NULL → '1990-01-01'.
  3) En/Ar cleanup:
       - If EN is NULL → use AR
       - If AR is NULL → use EN
  4) Uniqueness logic:
       - For each 4-key (ViewGroupID, NodeID, NodeValueID, NodeValueDate),
         keep it only if there is **one distinct final (En,Ar) pair** after fallback.
         Ignore if conflicting values exist.
  5) isActive logic:
       - First set all NodeData.isActive = 0 for current @ViewGroupID (or all if NULL).
       - Then re-activate (=1) and insert/update records that are valid for this run.

*******************************************************************************************/
CREATE   PROCEDURE [graphdb].[sp_NodeDataGenerate]
    @ViewGroupID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------------
        -- 1. Collect metadata and source view definitions
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
                vc.ColumnID,
                n.NodeID
            FROM graphdb.ViewGroupLists vgl
            JOIN graphdb.Views v
              ON v.ViewID = vgl.ViewID
            JOIN graphdb.ViewColumns vc
              ON vc.ViewID = v.ViewID
            JOIN graphdb.Nodes n
              ON n.ColumnID = vc.ColumnID
            WHERE n.GroupNodeID IS NOT NULL
              AND vc.ColumnID LIKE N'ID\_%\_ID' ESCAPE N'\'
              AND (@ViewGroupID IS NULL OR vgl.ViewGroupID = @ViewGroupID)
        )
        INSERT INTO #Sources
        SELECT
            ViewGroupID,
            ViewID,
            ViewDB,
            ViewSchema,
            ViewName,
            NodeID,
            ColumnID AS IdColumn,
            N'DATE_'   + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_DATE',
            N'ENTEXT_' + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_ENTEXT',
            N'ARTEXT_' + SUBSTRING(ColumnID, 4, LEN(ColumnID) - 6) + N'_ARTEXT'
        FROM IDCols;

        ------------------------------------------------------------
        -- 2. Load raw data into #NodeDataRaw
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#NodeDataRaw') IS NOT NULL DROP TABLE #NodeDataRaw;

        CREATE TABLE #NodeDataRaw
        (
            ViewGroupID   INT,
            NodeID        INT,
            NodeValueID   NVARCHAR(128),
            NodeValueEn   NVARCHAR(400),
            NodeValueAr   NVARCHAR(400),
            NodeValueDate DATE
        );

        DECLARE 
            @VGID INT, @ViewID INT, @ViewDB NVARCHAR(128), @ViewSchema NVARCHAR(128),
            @ViewNameEn NVARCHAR(128), @NodeID INT,
            @IdColumn SYSNAME, @DateColumn SYSNAME, @EnColumn SYSNAME, @ArColumn SYSNAME,
            @sql NVARCHAR(MAX);

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT ViewGroupID, ViewID, ViewDB, ViewSchema, ViewNameEn,
                   NodeID, IdColumn, DateColumn, EnColumn, ArColumn
            FROM #Sources;

        OPEN cur;
        FETCH NEXT FROM cur INTO @VGID, @ViewID, @ViewDB, @ViewSchema, @ViewNameEn,
                                @NodeID, @IdColumn, @DateColumn, @EnColumn, @ArColumn;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = N'
                INSERT INTO #NodeDataRaw
                (ViewGroupID, NodeID, NodeValueID, NodeValueEn, NodeValueAr, NodeValueDate)
                SELECT
                    ' + CAST(@VGID AS NVARCHAR(20)) + N',
                    ' + CAST(@NodeID AS NVARCHAR(20)) + N',
                    CONVERT(NVARCHAR(128), t.' + QUOTENAME(@IdColumn) + N'),
                    t.' + QUOTENAME(@EnColumn) + N',
                    t.' + QUOTENAME(@ArColumn) + N',
                    COALESCE(CONVERT(date, t.' + QUOTENAME(@DateColumn) + N'), CONVERT(date, ''1990-01-01''))
                FROM ' + QUOTENAME(@ViewDB) + N'.' + QUOTENAME(@ViewSchema) + N'.' + QUOTENAME(@ViewNameEn) + N' AS t
                WHERE t.' + QUOTENAME(@IdColumn) + N' IS NOT NULL
                  AND CONVERT(NVARCHAR(128), t.' + QUOTENAME(@IdColumn) + N') <> N''''
                  AND (t.' + QUOTENAME(@EnColumn) + N' IS NOT NULL
                       OR t.' + QUOTENAME(@ArColumn) + N' IS NOT NULL);';

            EXEC sys.sp_executesql @sql;

            FETCH NEXT FROM cur INTO @VGID, @ViewID, @ViewDB, @ViewSchema, @ViewNameEn,
                                    @NodeID, @IdColumn, @DateColumn, @EnColumn, @ArColumn;
        END

        CLOSE cur;
        DEALLOCATE cur;

        ------------------------------------------------------------
        -- 3. Deduplicate by 4-key after applying EN/AR fallback
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#NodeDataFinal') IS NOT NULL DROP TABLE #NodeDataFinal;

        ;WITH Prepared AS
        (
            SELECT
                r.ViewGroupID,
                r.NodeID,
                r.NodeValueID,
                r.NodeValueDate,
                FinalEn = COALESCE(r.NodeValueEn, r.NodeValueAr),
                FinalAr = COALESCE(r.NodeValueAr, r.NodeValueEn)
            FROM #NodeDataRaw r
        )
        SELECT
            p.ViewGroupID,
            p.NodeID,
            p.NodeValueID,
            p.NodeValueDate,
            NodeValueEn = MAX(p.FinalEn),
            NodeValueAr = MAX(p.FinalAr)
        INTO #NodeDataFinal
        FROM Prepared p
        GROUP BY
            p.ViewGroupID,
            p.NodeID,
            p.NodeValueID,
            p.NodeValueDate
        HAVING 
            COUNT(DISTINCT 
                ISNULL(p.FinalEn, N'#NULL#') + N'|' + ISNULL(p.FinalAr, N'#NULL#')
            ) = 1;

        DELETE FROM #NodeDataFinal
        WHERE NodeValueEn IS NULL AND NodeValueAr IS NULL;

        ------------------------------------------------------------
        -- 4. Reset isActive for relevant ViewGroup(s)
        ------------------------------------------------------------
        IF @ViewGroupID IS NULL
        BEGIN
            UPDATE graphdb.NodeData
            SET isActive = 0;
        END
        ELSE
        BEGIN
            UPDATE graphdb.NodeData
            SET isActive = 0
            WHERE ViewGroupID = @ViewGroupID;
        END

        ------------------------------------------------------------
        -- 5. Merge to NodeData
        ------------------------------------------------------------
        MERGE graphdb.NodeData AS target
        USING #NodeDataFinal AS src
           ON  target.ViewGroupID   = src.ViewGroupID
           AND target.NodeID        = src.NodeID
           AND target.NodeValueID   = src.NodeValueID
           AND target.NodeValueDate = src.NodeValueDate

        WHEN MATCHED THEN
            UPDATE SET
                target.NodeValueEn = src.NodeValueEn,
                target.NodeValueAr = src.NodeValueAr,
                target.isActive    = 1

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (ViewGroupID, NodeID, NodeValueID, NodeValueEn, NodeValueAr, NodeValueDate, isActive)
            VALUES (src.ViewGroupID, src.NodeID, src.NodeValueID, src.NodeValueEn, src.NodeValueAr, src.NodeValueDate, 1)
        ;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;

        DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@errMsg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesExpand]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************************
  Procedure: [graphdb].[sp_NodesExpand]

  PURPOSE
  ------------------------------------------------------------------------------------------
  Expand from a set of source node identities and return neighbor nodes
  (targets) with relation text, respecting filters and language.

  UPDATED RULE
  ------------------------------------------------------------------------------------------
  • Return only ONE edge per:
        (SourceGroupNodeID, SourceNodeValueID, TargetGroupNodeID, TargetNodeValueID)
    but also include:
        RelationCount = how many underlying RelationData rows exist
                        for that source–target pair (within date filter).

  • Among multiple rows for the same pair, we keep:
        - Latest TargetNodeValueDate (MAX)
        - Representative TargetNodeValueEn/Ar (MAX)
        - Representative RelationEn/Ar (MAX)

  PARAMETERS
  ------------------------------------------------------------------------------------------
  @ViewGroupID INT                      -- which view group to use
  @SourceNodeIdentities NodeIdentityTable READONLY
      -- columns: GroupNodeID, NodeValueID (logical source nodes)
  @FilterNodes NodeFilterTable READONLY
      -- columns: NodeID, FromDate, ToDate (which target node types and date window)

  @MaxNeighbors INT = 200               -- max distinct neighbors per source node
  @Lang NVARCHAR(10) = 'en-US'          -- 'en-US' or 'ar-AE' (for label selection)

*******************************************************************************************/
CREATE   PROCEDURE [graphdb].[sp_NodesExpand]
    @ViewGroupID INT,
    @SourceNodeIdentities [graphdb].[NodeIdentityTable] READONLY,
    @FilterNodes [graphdb].[NodeFilterTable] READONLY,
    @MaxNeighbors INT = 200,
    @Lang NVARCHAR(10) = N'en-US'
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH AggregatedRelations AS
    (
        SELECT
            R.ViewGroupID,
            -- Source
            R.SourceNodeID,
            R.SourceNodeValueID,
            R.SourceGroupNodeID,
            R.SourceNodeColor,
            -- Target (logical identity)
            R.TargetNodeID,
            R.TargetNodeValueID,
            R.TargetGroupNodeID,
            R.TargetNodeColor,

            -- Aggregated values
            MAX(R.RelationDataID)      AS RelationDataID,       -- representative ID
            MAX(R.TargetNodeValueDate) AS TargetNodeValueDate,  -- latest date
            MAX(R.TargetNodeValueEn)   AS TargetNodeValueEn,
            MAX(R.TargetNodeValueAr)   AS TargetNodeValueAr,
            MAX(R.RelationEn)          AS RelationEn,
            MAX(R.RelationAr)          AS RelationAr,
            COUNT(*)                   AS RelationCount         -- how many times
        FROM graphdb.vRelationData R
        INNER JOIN @SourceNodeIdentities S
            ON  R.SourceGroupNodeID = S.GroupNodeID
            AND R.SourceNodeValueID = S.NodeValueID
        INNER JOIN @FilterNodes F
            ON R.TargetNodeID = F.NodeID
        WHERE R.ViewGroupID = @ViewGroupID
          AND R.TargetNodeValueDate BETWEEN F.FromDate AND F.ToDate
        GROUP BY
            R.ViewGroupID,
            R.SourceNodeID,
            R.SourceNodeValueID,
            R.SourceGroupNodeID,
            R.SourceNodeColor,
            R.TargetNodeID,
            R.TargetNodeValueID,
            R.TargetGroupNodeID,
            R.TargetNodeColor
    ),
    RankedRelations AS
    (
        SELECT
            A.*,
            ROW_NUMBER() OVER (
                PARTITION BY A.SourceGroupNodeID, A.SourceNodeValueID
                ORDER BY A.TargetNodeValueDate DESC      -- latest neighbor first
            ) AS RowNum
        FROM AggregatedRelations A
    )
    SELECT
        R.RelationDataID,                 -- representative RelationData row
        -- Source
        R.SourceNodeID,
        R.SourceGroupNodeID,
        R.SourceNodeValueID,
        R.SourceNodeColor,
        -- Target
        R.TargetNodeID,
        R.TargetGroupNodeID,
        R.TargetNodeValueID,
        CASE WHEN @Lang = N'ar-AE'
             THEN R.TargetNodeValueAr
             ELSE R.TargetNodeValueEn
        END AS TargetNodeValue,
        R.TargetNodeColor,
        R.TargetNodeValueDate,
       -- Relation text with count suffix if >1
		CASE 
        WHEN @Lang = N'ar-AE' THEN
            CASE WHEN R.RelationCount > 1 
                 THEN CONCAT(R.RelationAr, N' (', R.RelationCount, N')')
                 ELSE R.RelationAr 
            END
        ELSE
            CASE WHEN R.RelationCount > 1 
                 THEN CONCAT(R.RelationEn, N' (', R.RelationCount, N')')
                 ELSE R.RelationEn 
            END
		END AS Relation,
        -- NEW: how many times this pair appears
        R.RelationCount
    FROM RankedRelations R
    WHERE R.RowNum <= @MaxNeighbors;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesFindPath]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_NodesFindPath]
    @ViewGroupID INT,
    @SourceNodeIdentities [graphdb].[NodeIdentityTable] READONLY,
    @MaxDepth INT = 4,
    @Lang NVARCHAR(10) = N'en-US'
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Resolve source NodeDataIDs for this ViewGroupID only
    ------------------------------------------------------------
    DECLARE @SourceNodeIDs TABLE (
        NodeDataID  BIGINT,
        GroupNodeID INT,
        NodeValueID NVARCHAR(128)
    );

    INSERT INTO @SourceNodeIDs (NodeDataID, GroupNodeID, NodeValueID)
    SELECT DISTINCT
        N.NodeDataID,
        S.GroupNodeID,
        S.NodeValueID
    FROM [graphdb].[vNodeData] AS N
    INNER JOIN @SourceNodeIdentities AS S
        ON  N.GroupNodeID  = S.GroupNodeID
        AND N.NodeValueID  = S.NodeValueID
    WHERE N.ViewGroupID = @ViewGroupID;   -- *** New: respect ViewGroupID ***

    -- Need at least 2 distinct starting nodes to find a path
    IF (SELECT COUNT(*) FROM @SourceNodeIDs) < 2
    BEGIN
        -- Return an empty result set with the expected shape
        SELECT TOP (0)
            RelationDataID        = CAST(NULL AS BIGINT),
            SourceNodeDataID      = CAST(NULL AS BIGINT),
            TargetNodeDataID      = CAST(NULL AS BIGINT),
            SourceNodeID          = CAST(NULL AS INT),
            SourceGroupNodeID     = CAST(NULL AS INT),
            SourceNodeValueID     = CAST(NULL AS NVARCHAR(128)),
            SourceNodeColor       = CAST(NULL AS NVARCHAR(20)),
            TargetNodeID          = CAST(NULL AS INT),
            TargetGroupNodeID     = CAST(NULL AS INT),
            TargetNodeValueID     = CAST(NULL AS NVARCHAR(128)),
            TargetNodeValue       = CAST(NULL AS NVARCHAR(400)),
            TargetNodeColor       = CAST(NULL AS NVARCHAR(20)),
            TargetNodeValueDate   = CAST(NULL AS DATE),
            Relation              = CAST(NULL AS NVARCHAR(256)),
            RelationCount         = CAST(NULL AS INT);
        RETURN;
    END;

    ------------------------------------------------------------
    -- 2. BFS from all sources (on vRelationData, both directions)
    ------------------------------------------------------------
    CREATE TABLE #Visited
    (
        NodeDataID        BIGINT,
        Depth             INT,
        OriginNodeDataID  BIGINT,
        ParentNodeDataID  BIGINT,  -- for backtracking
        RelationDataID    BIGINT,  -- edge used to reach this node
        PRIMARY KEY (NodeDataID, OriginNodeDataID)
    );

    -- Seed with the source nodes (each is its own origin at depth 0)
    INSERT INTO #Visited (NodeDataID, Depth, OriginNodeDataID, ParentNodeDataID, RelationDataID)
    SELECT
        NodeDataID,
        0              AS Depth,
        NodeDataID     AS OriginNodeDataID,
        NULL           AS ParentNodeDataID,
        NULL           AS RelationDataID
    FROM @SourceNodeIDs;

    DECLARE @CurrentDepth INT = 0;

    WHILE @CurrentDepth < @MaxDepth
    BEGIN
        ;WITH NewNodes AS
        (
            -- Forward edges: current -> target
            SELECT
                R.TargetNodeDataID        AS NodeDataID,
                @CurrentDepth + 1         AS Depth,
                V.OriginNodeDataID,
                V.NodeDataID              AS ParentNodeDataID,
                R.RelationDataID
            FROM #Visited AS V
            INNER JOIN [graphdb].[vRelationData] AS R
                ON V.NodeDataID = R.SourceNodeDataID
            WHERE V.Depth = @CurrentDepth
              AND R.ViewGroupID = @ViewGroupID

            UNION ALL

            -- Backward edges: current <- source (traverse other way)
            SELECT
                R.SourceNodeDataID        AS NodeDataID,
                @CurrentDepth + 1         AS Depth,
                V.OriginNodeDataID,
                V.NodeDataID              AS ParentNodeDataID,
                R.RelationDataID
            FROM #Visited AS V
            INNER JOIN [graphdb].[vRelationData] AS R
                ON V.NodeDataID = R.TargetNodeDataID
            WHERE V.Depth = @CurrentDepth
              AND R.ViewGroupID = @ViewGroupID
        ),
        RankedNodes AS
        (
            SELECT
                N.NodeDataID,
                N.Depth,
                N.OriginNodeDataID,
                N.ParentNodeDataID,
                N.RelationDataID,
                ROW_NUMBER() OVER (
                    PARTITION BY N.NodeDataID, N.OriginNodeDataID
                    ORDER BY N.ParentNodeDataID
                ) AS rn
            FROM NewNodes AS N
            WHERE NOT EXISTS
                  (
                      SELECT 1
                      FROM #Visited AS V
                      WHERE V.NodeDataID       = N.NodeDataID
                        AND V.OriginNodeDataID = N.OriginNodeDataID
                  )
        )
        INSERT INTO #Visited (NodeDataID, Depth, OriginNodeDataID, ParentNodeDataID, RelationDataID)
        SELECT
            NodeDataID,
            Depth,
            OriginNodeDataID,
            ParentNodeDataID,
            RelationDataID
        FROM RankedNodes
        WHERE rn = 1;

        IF @@ROWCOUNT = 0
            BREAK;  -- nothing new found at this depth

        SET @CurrentDepth = @CurrentDepth + 1;
    END;

    ------------------------------------------------------------
    -- 3. Find "meeting" nodes (visited by more than one origin)
    ------------------------------------------------------------
    SELECT DISTINCT
        V.NodeDataID
    INTO #MeetingPoints
    FROM #Visited AS V
    GROUP BY V.NodeDataID
    HAVING COUNT(DISTINCT V.OriginNodeDataID) > 1;

    -- Also treat "one source reached another source" as a meeting
    INSERT INTO #MeetingPoints (NodeDataID)
    SELECT DISTINCT
        V.NodeDataID
    FROM #Visited AS V
    WHERE V.NodeDataID IN (SELECT NodeDataID FROM @SourceNodeIDs)
      AND V.OriginNodeDataID <> V.NodeDataID;

    -- If still nothing, no connecting paths
    IF NOT EXISTS (SELECT 1 FROM #MeetingPoints)
    BEGIN
        SELECT TOP (0)
            RelationDataID        = CAST(NULL AS BIGINT),
            SourceNodeDataID      = CAST(NULL AS BIGINT),
            TargetNodeDataID      = CAST(NULL AS BIGINT),
            SourceNodeID          = CAST(NULL AS INT),
            SourceGroupNodeID     = CAST(NULL AS INT),
            SourceNodeValueID     = CAST(NULL AS NVARCHAR(128)),
            SourceNodeColor       = CAST(NULL AS NVARCHAR(20)),
            TargetNodeID          = CAST(NULL AS INT),
            TargetGroupNodeID     = CAST(NULL AS INT),
            TargetNodeValueID     = CAST(NULL AS NVARCHAR(128)),
            TargetNodeValue       = CAST(NULL AS NVARCHAR(400)),
            TargetNodeColor       = CAST(NULL AS NVARCHAR(20)),
            TargetNodeValueDate   = CAST(NULL AS DATE),
            Relation              = CAST(NULL AS NVARCHAR(256)),
            RelationCount         = CAST(NULL AS INT);
        RETURN;
    END;

    ------------------------------------------------------------
    -- 4. Backtrack from meeting points to get all edges on paths
    ------------------------------------------------------------
    ;WITH ValidPathNodes AS
    (
        -- Start from the meeting nodes
        SELECT V.*
        FROM #Visited AS V
        INNER JOIN #MeetingPoints AS M
            ON V.NodeDataID = M.NodeDataID

        UNION ALL

        -- Walk backwards via ParentNodeDataID
        SELECT P.*
        FROM #Visited AS P
        INNER JOIN ValidPathNodes AS C
            ON  P.NodeDataID       = C.ParentNodeDataID
            AND P.OriginNodeDataID = C.OriginNodeDataID
    )
    SELECT DISTINCT
        VPN.RelationDataID
    INTO #ValidEdges
    FROM ValidPathNodes AS VPN
    WHERE VPN.RelationDataID IS NOT NULL;

    ------------------------------------------------------------
    -- 5. Aggregate edges:
    --    - Only one edge per (SourceGroupNodeID, SourceNodeValueID,
    --                         TargetGroupNodeID, TargetNodeValueID)
    --    - RelationCount = number of raw edges collapsed
    --    - Use MAX() for text and latest date
    ------------------------------------------------------------
    ;WITH PathEdges AS
    (
        SELECT R.*
        FROM [graphdb].[vRelationData] AS R
        INNER JOIN #ValidEdges AS VE
            ON R.RelationDataID = VE.RelationDataID
        WHERE R.ViewGroupID = @ViewGroupID
    ),
    AggregatedEdges AS
    (
        SELECT
            RelationDataID      = MIN(P.RelationDataID),
            SourceNodeDataID    = MIN(P.SourceNodeDataID),
            TargetNodeDataID    = MIN(P.TargetNodeDataID),

            P.SourceNodeID,
            P.SourceGroupNodeID,
            P.SourceNodeValueID,
            P.SourceNodeColor,

            P.TargetNodeID,
            P.TargetGroupNodeID,
            P.TargetNodeValueID,

            TargetNodeValueEn   = MAX(P.TargetNodeValueEn),
            TargetNodeValueAr   = MAX(P.TargetNodeValueAr),
            TargetNodeColor     = MAX(P.TargetNodeColor),
            TargetNodeValueDate = MAX(P.TargetNodeValueDate),

            RelationEn          = MAX(P.RelationEn),
            RelationAr          = MAX(P.RelationAr),

            RelationCount       = COUNT(*)    -- how many raw edges merged
        FROM PathEdges AS P
        GROUP BY
            P.SourceNodeID,
            P.SourceGroupNodeID,
            P.SourceNodeValueID,
            P.SourceNodeColor,
            P.TargetNodeID,
            P.TargetGroupNodeID,
            P.TargetNodeValueID
    )
    SELECT
        AE.RelationDataID,
        AE.SourceNodeDataID,
        AE.TargetNodeDataID,

        -- Source identity
        AE.SourceNodeID,
        AE.SourceGroupNodeID,
        AE.SourceNodeValueID,
        AE.SourceNodeColor,

        -- Target identity
        AE.TargetNodeID,
        AE.TargetGroupNodeID,
        AE.TargetNodeValueID,
        TargetNodeValue =
            CASE WHEN @Lang = N'ar-AE'
                 THEN AE.TargetNodeValueAr
                 ELSE AE.TargetNodeValueEn
            END,
        AE.TargetNodeColor,
        AE.TargetNodeValueDate,

        -- Relation text with count suffix if > 1
        Relation =
            CASE WHEN @Lang = N'ar-AE'
                 THEN
                     CASE WHEN AE.RelationCount > 1 AND AE.RelationAr IS NOT NULL
                          THEN AE.RelationAr + N' (' + CAST(AE.RelationCount AS NVARCHAR(20)) + N')'
                          ELSE AE.RelationAr
                     END
                 ELSE
                     CASE WHEN AE.RelationCount > 1 AND AE.RelationEn IS NOT NULL
                          THEN AE.RelationEn + N' (' + CAST(AE.RelationCount AS NVARCHAR(20)) + N')'
                          ELSE AE.RelationEn
                     END
            END,
        AE.RelationCount
    FROM AggregatedEdges AS AE;

    ------------------------------------------------------------
    -- 6. Cleanup
    ------------------------------------------------------------
    DROP TABLE #Visited;
    DROP TABLE #MeetingPoints;
    DROP TABLE #ValidEdges;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_NodesGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
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
    -- 4. (Node pruning to avoid FK conflicts with Relations)
    ----------------------------------------------------------------
     IF @PruneMissing = 1
     BEGIN
       UPDATE s SET S.GroupNodeID=NULL
       FROM graphdb.Nodes s
       LEFT JOIN #All a
         ON a.ColumnID = s.ColumnID
       WHERE a.ColumnID IS NULL;
     END

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
/****** Object:  StoredProcedure [graphdb].[sp_NodeUpdate]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  StoredProcedure [graphdb].[sp_RelationDataGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************************************
  Procedure: [graphdb].[sp_RelationDataGenerate]

  PURPOSE
  ------------------------------------------------------------------------------------------
  Populate [graphdb].[RelationData] from:
    • [graphdb].[Relations]
    • ViewGroup views (ViewGroupLists + Views + ViewColumns + Nodes)
    • [graphdb].[NodeData]

  KEY RULES
  ------------------------------------------------------------------------------------------
  1) NodeData uniqueness:
       NodeData is unique per:
         (ViewGroupID, NodeID, NodeValueID, NodeValueDate)

     So this procedure joins NodeData using:
         ViewGroupID + NodeID + NodeValueID + NodeValueDate

  2) Only active NodeData:
       Only rows with NodeData.isActive = 1 are used.

  3) Date handling:
       For each node in the view:
         - ID_*_ID     → NodeValueID
         - DATE_*_DATE → NodeValueDate

       If DATE_*_DATE is NULL in the view, we treat it as '1990-01-01'
       (COALESCE(...) to match NodeData default behavior).

  4) Relation text:
       - If RelationNodeID is set:
           • read ENED_*_ENED / ARED_*_ARED from the view row.
       - Else:
           • use Relations.RelationEn / Relations.RelationAr.

  5) RelationValueDate:
       - Taken from the source node DATE_*_DATE (with NULL → '1990-01-01').

  PARAMETERS
  ------------------------------------------------------------------------------------------
  @ViewGroupID INT
      NULL  → process all ViewGroups
      value → process only that ViewGroupID

*******************************************************************************************/
CREATE   PROCEDURE [graphdb].[sp_RelationDataGenerate]
    @ViewGroupID INT = NULL      -- NULL = all groups
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------------
        -- 0. Mapping metadata per (Relation, View)
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
            TargetNodeID      INT,       -- DisplayNodeID

            SourceIdCol       SYSNAME,
            TargetIdCol       SYSNAME,
            SourceDateCol     SYSNAME,   -- DATE_*_DATE for source
            TargetDateCol     SYSNAME,   -- DATE_*_DATE for target

            HasRelationNode   BIT,
            RelEnCol          SYSNAME NULL,   -- ENED_*_ENED
            RelArCol          SYSNAME NULL,   -- ARED_*_ARED

            RelationEnDefault NVARCHAR(128) NULL,  -- from Relations
            RelationArDefault NVARCHAR(128) NULL
        );

        ------------------------------------------------------------
        -- 1. Build metadata from Relations + views + nodes
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
        RelCols AS (
            -- For RelationNodeID we want ENED_*_ENED / ARED_*_ARED
            SELECT
                vnc.ViewGroupID,
                vnc.ViewID,
                vnc.NodeID,
                vnc.ColumnID,
                MiddleKey  = SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6),
                EnColName  = N'ENED_' + SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6) + N'_ENED',
                ArColName  = N'ARED_' + SUBSTRING(vnc.ColumnID, 4, LEN(vnc.ColumnID) - 6) + N'_ARED'
            FROM ViewNodeCols vnc
        )
        INSERT INTO #RelSources (
            ViewGroupID, RelationID, ViewID, ViewDB, ViewSchema, ViewNameEn,
            SourceNodeID, TargetNodeID,
            SourceIdCol, TargetIdCol, SourceDateCol, TargetDateCol,
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

            SourceDateCol = N'DATE_' + SUBSTRING(src.ColumnID, 4, LEN(src.ColumnID) - 6) + N'_DATE',
            TargetDateCol = N'DATE_' + SUBSTRING(tgt.ColumnID, 4, LEN(tgt.ColumnID) - 6) + N'_DATE',

            HasRelationNode   = CASE WHEN ar.RelationNodeID IS NOT NULL THEN 1 ELSE 0 END,
            RelEnCol          = rc.EnColName,
            RelArCol          = rc.ArColName,

            RelationEnDefault = ar.RelationEn,
            RelationArDefault = ar.RelationAr
        FROM ActiveRel ar
        JOIN VGViews vgv
          ON vgv.ViewGroupID = ar.ViewGroupID
        JOIN ViewNodeCols src
          ON src.ViewID = vgv.ViewID AND src.NodeID = ar.SourceNodeID
        JOIN ViewNodeCols tgt
          ON tgt.ViewID = vgv.ViewID AND tgt.NodeID = ar.DisplayNodeID
        LEFT JOIN RelCols rc
          ON rc.ViewGroupID = vgv.ViewGroupID
         AND rc.ViewID      = vgv.ViewID
         AND rc.NodeID      = ar.RelationNodeID;

        ------------------------------------------------------------
        -- 2. Build RelationData rows into #RelationDataNew
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
            @TargetDateCol  SYSNAME,

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
                SourceIdCol, TargetIdCol, SourceDateCol, TargetDateCol,
                HasRelationNode, RelEnCol, RelArCol,
                RelationEnDefault, RelationArDefault
            FROM #RelSources;

        OPEN curRel;
        FETCH NEXT FROM curRel INTO
            @VGID, @RelID, @ViewID, @ViewDB, @ViewSchema, @ViewName,
            @SourceNodeID, @TargetNodeID,
            @SourceIdCol, @TargetIdCol, @SourceDateCol, @TargetDateCol,
            @HasRelNode, @RelEnCol, @RelArCol,
            @RelEnDefault, @RelArDefault;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            --------------------------------------------------------
            -- Prepare default relation text literals
            --------------------------------------------------------
            IF @RelEnDefault IS NULL
                SET @RelEnLit = N'NULL';
            ELSE
                SET @RelEnLit = N'N''' + REPLACE(@RelEnDefault, N'''', N'''''') + N'''';

            IF @RelArDefault IS NULL
                SET @RelArLit = N'NULL';
            ELSE
                SET @RelArLit = N'N''' + REPLACE(@RelArDefault, N'''', N'''''') + N'''';

            --------------------------------------------------------
            -- Build dynamic SQL for each relation/view mapping
            -- IMPORTANT: NodeData join includes NodeValueDate now.
            --------------------------------------------------------
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
                    COALESCE(CONVERT(date, t.' + QUOTENAME(@SourceDateCol) + N'), CONVERT(date, ''1990-01-01'')) AS RelationValueDate
                FROM ' + QUOTENAME(@ViewDB) + N'.' + QUOTENAME(@ViewSchema) + N'.' + QUOTENAME(@ViewName) + N' AS t
                JOIN graphdb.NodeData nd_src
                  ON nd_src.ViewGroupID   = ' + CAST(@VGID AS NVARCHAR(20)) + N'
                 AND nd_src.NodeID        = ' + CAST(@SourceNodeID AS NVARCHAR(20)) + N'
                 AND nd_src.NodeValueID   = CONVERT(NVARCHAR(128), t.' + QUOTENAME(@SourceIdCol) + N')
                 AND nd_src.NodeValueDate = COALESCE(CONVERT(date, t.' + QUOTENAME(@SourceDateCol) + N'), CONVERT(date, ''1990-01-01''))
                 AND nd_src.isActive      = 1
                JOIN graphdb.NodeData nd_tgt
                  ON nd_tgt.ViewGroupID   = ' + CAST(@VGID AS NVARCHAR(20)) + N'
                 AND nd_tgt.NodeID        = ' + CAST(@TargetNodeID AS NVARCHAR(20)) + N'
                 AND nd_tgt.NodeValueID   = CONVERT(NVARCHAR(128), t.' + QUOTENAME(@TargetIdCol) + N')
                 AND nd_tgt.NodeValueDate = COALESCE(CONVERT(date, t.' + QUOTENAME(@TargetDateCol) + N'), CONVERT(date, ''1990-01-01''))
                 AND nd_tgt.isActive      = 1
                WHERE t.' + QUOTENAME(@SourceIdCol) + N' IS NOT NULL
                  AND t.' + QUOTENAME(@TargetIdCol) + N' IS NOT NULL;
            ';

            EXEC sys.sp_executesql @sql;

            FETCH NEXT FROM curRel INTO
                @VGID, @RelID, @ViewID, @ViewDB, @ViewSchema, @ViewName,
                @SourceNodeID, @TargetNodeID,
                @SourceIdCol, @TargetIdCol, @SourceDateCol, @TargetDateCol,
                @HasRelNode, @RelEnCol, @RelArCol,
                @RelEnDefault, @RelArDefault;
        END

        CLOSE curRel;
        DEALLOCATE curRel;

        ------------------------------------------------------------
        -- 3. Replace RelationData rows for this ViewGroup
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

		------------------------------------------------------------
		-- 4. Cleanup: Remove inactive NodeData rows for this ViewGroup
		------------------------------------------------------------
		IF @ViewGroupID IS NULL
		BEGIN
			DELETE FROM graphdb.NodeData
			WHERE isActive = 0;
		END
		ELSE
		BEGIN
			DELETE FROM graphdb.NodeData
			WHERE ViewGroupID = @ViewGroupID
			  AND isActive = 0;
		END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;

        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@msg, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [graphdb].[sp_RelationsGenerate]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  StoredProcedure [graphdb].[sp_RelationsList]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  StoredProcedure [graphdb].[sp_RelationUpdate]    Script Date: 09/12/2025 12:35:44 AM ******/
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
/****** Object:  StoredProcedure [graphdb].[sp_ViewGroupNodesList]    Script Date: 09/12/2025 12:35:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [graphdb].[sp_ViewGroupNodesList]
    @ViewGroupID INT,
    @Lang        NVARCHAR(10) = N'en-US'   -- 'en-US' or 'ar-AE'
AS
/*
exec [graphdb].[sp_ViewGroupNodesList] @ViewGroupID=1
*/
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

            n.ColumnColor,
			n.isDefaultSearch,
			CONVERT(VARCHAR(10), DATEADD(MONTH, -n.SearchMonths, GETDATE()), 103) as FromDate,
			CONVERT(VARCHAR(10), GETDATE(), 103) as ToDate
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
/****** Object:  StoredProcedure [graphdb].[sp_ViewGroupsList]    Script Date: 09/12/2025 12:35:44 AM ******/
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
