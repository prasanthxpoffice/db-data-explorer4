CREATE NONCLUSTERED INDEX IX_RelationData_NodesExpand
ON [graphdb].[RelationData]
(
    ViewGroupID,
    SourceNodeDataID,
    TargetNodeDataID
)
INCLUDE
(
    RelationEn,
    RelationAr,
    RelationValueDate
);