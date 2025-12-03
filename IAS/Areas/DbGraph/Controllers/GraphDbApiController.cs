using IAS.Areas.DbGraph.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace IAS.Areas.DbGraph.Controllers
{
    [RouteArea("DbGraph", AreaPrefix = "")]
    [RoutePrefix("graphapi")]
    public class GraphDbApiController : Controller
    {
        private readonly string _connectionString;

        public GraphDbApiController()
        {
            var defaultConnection = ConfigurationManager.ConnectionStrings["IASConnectionString"];
            _connectionString = defaultConnection?.ConnectionString;

            if (string.IsNullOrEmpty(_connectionString))
            {
                throw new ConfigurationErrorsException("Connection string 'DefaultConnection' not found in Web.config.");
            }
        }

        [HttpGet]
        [Route("health")]
        public ActionResult Health()
        {
            return Json(new { status = "ok", utc = DateTimeOffset.UtcNow }, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [Route("viewgroups")]
        public ActionResult GetViewGroups(string lang = "en")
        {
            // Map simple lang code to full culture code expected by SP
            string sqlLang = (lang == "ar") ? "ar-AE" : "en-US";

            var dt = new DataTable();
            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_ViewGroupsList]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [Route("viewgroupnodes")]
        public ActionResult GetViewGroupNodes(int viewGroupId, string lang = "en")
        {
            string sqlLang = (lang == "ar") ? "ar-AE" : "en-US";
            var dt = new DataTable();

            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_ViewGroupNodesList]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@ViewGroupID", viewGroupId);
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [Route("nodedataautocomplete")]
        public ActionResult NodeDataAutoComplete(int NodeID, string SearchText, int TopCount = 20, string Lang = "en")
        {
            // Map simple lang code to full culture code expected by SP
            string sqlLang = (Lang == "ar") ? "ar-AE" : "en-US";
            var dt = new DataTable();

            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_NodeDataAutoComplete]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@NodeID", NodeID);
                    cmd.Parameters.AddWithValue("@SearchText", SearchText ?? "");
                    cmd.Parameters.AddWithValue("@TopCount", TopCount);
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [Route("groupnodes")]
        public ActionResult GroupNodeList(string lang = "en")
        {
            // Map simple lang code to full culture code expected by SP
            // Note: The user's SP seems to accept 'En' or 'Ar' directly, but let's stick to the pattern or pass as is?
            // User SP: @Lang NVARCHAR(10) = 'En' -- 'En' or 'Ar'
            // Existing code maps "ar" -> "ar-AE". 
            // Let's assume the SP handles 'ar-AE' or we should pass 'Ar'/'En'.
            // Looking at the SP definition provided: 
            // CASE WHEN LOWER(@Lang) = 'ar' THEN ...
            // So 'ar-AE' might fail if it strictly checks = 'ar'. 
            // However, existing methods use "ar-AE". Let's check existing SPs? 
            // Actually, let's just pass "Ar" or "En" to be safe based on the provided SP script.
            
            string sqlLang = (lang.ToLower() == "ar") ? "Ar" : "En";

            var dt = new DataTable();
            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_GroupNodeList]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [Route("nodeupdate")]
        public ActionResult NodeUpdate(int NodeID, int? GroupNodeID = null, string ColumnEn = null, string ColumnAr = null, string ColumnColor = null)
        {
            try
            {
                using (var conn = new SqlConnection(_connectionString))
                {
                    using (var cmd = new SqlCommand("[graphdb].[sp_NodeUpdate]", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@NodeID", NodeID);
                        cmd.Parameters.AddWithValue("@GroupNodeID", (object)GroupNodeID ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@ColumnEn", (object)ColumnEn ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@ColumnAr", (object)ColumnAr ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@ColumnColor", (object)ColumnColor ?? DBNull.Value);

                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
                return Json(new { success = true, message = "Node updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }
 
        [HttpGet]
        [Route("relationslist")]
        public ActionResult RelationsList(int ViewGroupID, bool OnlyActive = false, string lang = "en")
        {
            // Map simple lang code to full culture code expected by SP
            string sqlLang = (lang == "ar") ? "ar-AE" : "en-US";
            var dt = new DataTable();
            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_RelationsList]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@ViewGroupID", ViewGroupID);
                    cmd.Parameters.AddWithValue("@OnlyActive", OnlyActive);
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [Route("relationupdate")]
        public ActionResult RelationUpdate(int RelationID, int? RelationNodeID, string RelationEn, string RelationAr, bool IsActive)
        {
            try
            {
                // Logic to handle mutual exclusivity enforced by SP
                if (RelationNodeID.HasValue && RelationNodeID.Value > 0)
                {
                    // If NodeID is provided, names must be null
                    RelationEn = null;
                    RelationAr = null;
                }
                else
                {
                    // If NodeID is not provided (or invalid), ensure it's null
                    RelationNodeID = null;
                    // Names are required by SP if NodeID is null, but we pass what we have
                }

                using (var conn = new SqlConnection(_connectionString))
                {
                    using (var cmd = new SqlCommand("[graphdb].[sp_RelationUpdate]", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@RelationID", RelationID);
                        cmd.Parameters.AddWithValue("@RelationNodeID", (object)RelationNodeID ?? DBNull.Value);
                        
                        // Handle empty strings as DBNull to satisfy SP's NULL checks if needed, 
                        // though SP also does NULLIF(..., ''). 
                        // Explicitly passing DBNull is safer for the "IS NULL" checks.
                        cmd.Parameters.AddWithValue("@RelationEn", string.IsNullOrWhiteSpace(RelationEn) ? (object)DBNull.Value : RelationEn);
                        cmd.Parameters.AddWithValue("@RelationAr", string.IsNullOrWhiteSpace(RelationAr) ? (object)DBNull.Value : RelationAr);
                        
                        cmd.Parameters.AddWithValue("@IsActive", IsActive);

                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
                return Json(new { success = true, message = "Relation updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        [HttpPost]
        [Route("nodessearch")]
        public ActionResult NodesSearch(List<int> nodeDataIds, string lang = "en")
        {
            string sqlLang = (lang == "ar") ? "ar-AE" : "en-US";
            var dt = new DataTable();

            // Create DataTable for TVP
            var tvp = new DataTable();
            tvp.Columns.Add("NodeDataID", typeof(int));
            if (nodeDataIds != null)
            {
                foreach (var id in nodeDataIds)
                {
                    tvp.Rows.Add(id);
                }
            }

            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_NodesSearch]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);
                    
                    var tvpParam = cmd.Parameters.AddWithValue("@NodeDataIDs", tvp);
                    tvpParam.SqlDbType = SqlDbType.Structured;
                    tvpParam.TypeName = "[graphdb].[NodeDataIDTable]";

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results);
        }

        [HttpPost]
        [Route("nodesexpand")]
        public ActionResult NodesExpand(NodesExpandRequest request)
        {
            string sqlLang = (request.Lang == "ar") ? "ar-AE" : "en-US";
            var dt = new DataTable();

            // Create DataTable for Source Nodes TVP
            var sourceTvp = new DataTable();
            sourceTvp.Columns.Add("NodeDataID", typeof(int));
            if (request.SourceNodeDataIDs != null)
            {
                foreach (var id in request.SourceNodeDataIDs)
                {
                    sourceTvp.Rows.Add(id);
                }
            }

            // Create DataTable for Filter Nodes TVP
            var filterTvp = new DataTable();
            filterTvp.Columns.Add("NodeID", typeof(int));
            filterTvp.Columns.Add("FromDate", typeof(DateTime));
            filterTvp.Columns.Add("ToDate", typeof(DateTime));
            
            if (request.FilterNodes != null)
            {
                foreach (var filter in request.FilterNodes)
                {
                    filterTvp.Rows.Add(filter.NodeID, filter.FromDate ?? (object)DBNull.Value, filter.ToDate ?? (object)DBNull.Value);
                }
            }

            using (var conn = new SqlConnection(_connectionString))
            {
                using (var cmd = new SqlCommand("[graphdb].[sp_NodesExpand]", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@ViewGroupID", request.ViewGroupID);
                    cmd.Parameters.AddWithValue("@MaxNeighbors", request.MaxNeighbors);
                    cmd.Parameters.AddWithValue("@Lang", sqlLang);
                    
                    var pSource = cmd.Parameters.AddWithValue("@SourceNodeDataIDs", sourceTvp);
                    pSource.SqlDbType = SqlDbType.Structured;
                    pSource.TypeName = "[graphdb].[NodeDataIDTable]";

                    var pFilter = cmd.Parameters.AddWithValue("@FilterNodes", filterTvp);
                    pFilter.SqlDbType = SqlDbType.Structured;
                    pFilter.TypeName = "[graphdb].[NodeFilterTable]";

                    conn.Open();
                    using (var reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }

            var results = dt.AsEnumerable().Select(row =>
                dt.Columns.Cast<DataColumn>().ToDictionary(col => col.ColumnName, col => row[col])
            ).ToList();

            return LargeJson(results);
        }

        protected JsonResult LargeJson(object data, JsonRequestBehavior behavior = JsonRequestBehavior.DenyGet)
        {
            return new JsonResult
            {
                Data = data,
                JsonRequestBehavior = behavior,
                MaxJsonLength = int.MaxValue
            };
        }
    }
}
