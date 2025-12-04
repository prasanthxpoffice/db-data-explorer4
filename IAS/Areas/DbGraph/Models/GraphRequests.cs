using System;
using System.Collections.Generic;

namespace IAS.Areas.DbGraph.Models
{
    public class GraphRequestBase
    {
        public GraphRequestBase()
        {
            ViewIds = new List<int>();
        }

        public string Lang { get; set; }
        public List<int> ViewIds { get; set; }
    }

    public class NodeTypesRequest : GraphRequestBase
    {
    }

    public class LegendsRequest : GraphRequestBase
    {
        public LegendsRequest()
        {
            OnlyActive = true;
        }

        public bool? OnlyActive { get; set; }
    }

    public class ItemsRequest : GraphRequestBase
    {
        public string ColId { get; set; }
        public int MaxCount { get; set; }
    }

    public class NodeSearchDto
    {
        public string SourceColId { get; set; }
        public string SourceId { get; set; }
    }

    public class BulkExpandRequest : GraphRequestBase
    {
        public BulkExpandRequest()
        {
            SearchList = new List<NodeSearchDto>();
        }

        public List<NodeSearchDto> SearchList { get; set; }
        public int MaxNodes { get; set; }
        public List<LegendFilterDto> Filters { get; set; }
    }

    public class LegendFilterDto
    {
        public string DestinationColId { get; set; }
        public string FromDate { get; set; }
        public string ToDate { get; set; }
    }

    public class MasterNodeUpdateRequest
    {
        public string Column_ID { get; set; }
        public string ColumnEn { get; set; }
        public string ColumnAr { get; set; }
        public int GroupNodeID { get; set; }
        public bool? IsActive { get; set; }
        public string ColumnColor { get; set; }
        public string Lang { get; set; }
        public string UserId { get; set; }
    }

    public class SaveRelationRequest
    {
        public string Source_Column_ID { get; set; }
        public string Search_Column_ID { get; set; }
        public string Display_Column_ID { get; set; }
        public string Direction { get; set; }
        public string Relation_Column_ID { get; set; }
        public string RelationEn { get; set; }
        public string RelationAr { get; set; }
    }

    public class DeleteRelationRequest
    {
        public int RelationID { get; set; }
    }

    public class NodeFilterModel
    {
        public int NodeID { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }

    public class NodeIdentity
    {
        public int GroupNodeID { get; set; }
        public string NodeValueID { get; set; }
    }

    public class NodesExpandRequest
    {
        public int ViewGroupID { get; set; }
        public List<NodeIdentity> SourceNodeIdentities { get; set; }
        public List<NodeFilterModel> FilterNodes { get; set; }
        public int MaxNeighbors { get; set; } = 5;
        public string Lang { get; set; } = "en";
    }

    public class NodesFindPathRequest
    {
        public int ViewGroupID { get; set; }
        public List<NodeIdentity> SourceNodeIdentities { get; set; }
        public int MaxDepth { get; set; } = 4;
        public string Lang { get; set; } = "en-US";
    }
}
