$source = @"
namespace SVC
{
	public class vDisk
	{
		public vDisk()
		{
			
		}

		public string capacity { get; set; }
		public string compressed_copy_count { get; set; }
		public string ComputerName { get; set; }
		public string copy_count { get; set; }
		public string fast_write_state { get; set; }
		public string FC_id { get; set; }
		public string fc_map_count { get; set; }
		public string FC_name { get; set; }
		public string formatting { get; set; }
		public string id { get; set; }
		public string IO_group_id { get; set; }
		public string IO_group_name { get; set; }
		public string mdisk_grp_id { get; set; }
		public string mdisk_grp_name { get; set; }
		public string name { get; set; }
		public string parent_mdisk_grp_id { get; set; }
		public string parent_mdisk_grp_name { get; set; }
		public string RC_change { get; set; }
		public string RC_id { get; set; }
		public string RC_name { get; set; }
		public string se_copy_count { get; set; }
		public string status { get; set; }
		public string type { get; set; }
		public string vdisk_UID { get; set; }

		
	}
	
	public class vDiskID : vDisk
	{
		public vDiskID()
		{
			
		}

		public string access_IO_group_count { get; set; }
		public string autoexpand { get; set; }
		public string cache { get; set; }
		public string cfast_write_state { get; set; }
		public string cmdisk_grp_id { get; set; }
		public string cmdisk_grp_name { get; set; }
		public string cmdisk_id { get; set; }
		public string cmdisk_name { get; set; }
		public string compressed_copy { get; set; }
		public string copy_id { get; set; }
		public string cparent_mdisk_grp_id { get; set; }
		public string cparent_mdisk_grp_name { get; set; }
		public string cstatus { get; set; }
		public string ctier { get; set; }
		public string ctier_capacity { get; set; }
		public string ctype { get; set; }
		public string easy_tier { get; set; }
		public string easy_tier_status { get; set; }
		public string filesystem { get; set; }
		public string formatted { get; set; }
		public string free_capacity { get; set; }
		public string grainsize { get; set; }
		public string last_access_time { get; set; }
		public string mdisk_id { get; set; }
		public string mdisk_name { get; set; }
		public string mirror_write_priority { get; set; }
		public string overallocation { get; set; }
		public string owner_id { get; set; }
		public string owner_name { get; set; }
		public string owner_type { get; set; }
		public string preferred_node_id { get; set; }
		public string primary { get; set; }
		public string real_capacity { get; set; }
		public string se_copy { get; set; }
		public string sync { get; set; }
		public string sync_rate { get; set; }
		public string throttling { get; set; }
		public string tier { get; set; }
		public string tier_capacity { get; set; }
		public string udid { get; set; }
		public string uncompressed_used_capacity { get; set; }
		public string used_capacity { get; set; }
		public string warning { get; set; }
	}
	
	public class Replication
	{
		public Replication()
		{
			
		}
		
		public string aux_cluster_id { get; set; }
		public string aux_cluster_name { get; set; }
		public string aux_vdisk_id { get; set; }
		public string aux_vdisk_name { get; set; }
		public string bg_copy_priority { get; set; }
		public string ComputerName { get; set; }
		public string consistency_group_id { get; set; }
		public string consistency_group_name { get; set; }
		public string copy_type { get; set; }
		public string cycling_mode { get; set; }
		public string freeze_time { get; set; }
		public string id { get; set; }
		public string master_cluster_id { get; set; }
		public string master_cluster_name { get; set; }
		public string master_vdisk_id { get; set; }
		public string master_vdisk_name { get; set; }
		public string name { get; set; }
		public string primary { get; set; }
		public string progress { get; set; }
		public string state { get; set; }
		
		
	}
	
	public class ReplicationID : Replication
	{
		public ReplicationID()
		{
			
		}
		
		public string aux_change_vdisk_id { get; set; }
		public string aux_change_vdisk_name { get; set; }
		public string cycle_period_seconds { get; set; }
		public string master_change_vdisk_id { get; set; }
		public string master_change_vdisk_name { get; set; }
		public string status { get; set; }
		public string sync { get; set; }
	}
	
	public class Drive
	{
		public Drive()
		{
			
		}
		
		public string auto_manage { get; set; }
		public string capacity { get; set; }
		public string ComputerName { get; set; }
		public string enclosure_id { get; set; }
		public string error_sequence_number { get; set; }
		public string id { get; set; }
		public string mdisk_id { get; set; }
		public string mdisk_name { get; set; }
		public string member_id { get; set; }
		public string node_id { get; set; }
		public string node_name { get; set; }
		public string slot_id { get; set; }
		public string status { get; set; }
		public string tech_type { get; set; }
		public string use { get; set; }
		
		
	}
	
	public class DriveId : Drive
	{
		public DriveId()
		{
			
		}
		
		public string block_size { get; set; }
		public string firmware_level { get; set; }
		public string FPGA_level { get; set; }
		public string FRU_identity { get; set; }
		public string FRU_part_number { get; set; }
		public string interface_speed { get; set; }
		public string port_1_status { get; set; }
		public string port_2_status { get; set; }
		public string product_id { get; set; }
		public string protection_enabled { get; set; }
		public string quorum_id { get; set; }
		public string RPM { get; set; }
		public string UID { get; set; }
		public string vendor_id { get; set; }
	}
	
	public class FCMap
	{
		public FCMap()
		{
			
		}
		
		public string id { get; set; }
		public string name { get; set; }
		public string source_vdisk_id { get; set; }
		public string source_vdisk_name { get; set; }
		public string target_vdisk_id { get; set; }
		public string target_vdisk_name { get; set; }
		public string group_id { get; set; }
		public string group_name { get; set; }
		public string status { get; set; }
		public string progress { get; set; }
		public string copy_rate { get; set; }
		public string clean_progress { get; set; }
		public string incremental { get; set; }
		public string partner_FC_id { get; set; }
		public string partner_FC_name { get; set; }
		public string restoring { get; set; }
		public string start_time { get; set; }
		public string rc_controlled { get; set; }
		
		
	}
	
	public class FCMapId : FCMap
	{
		public FCMapId()
		{
			
		}
		
		public string dependent_mappings { get; set; }
		public string autodelete { get; set; }
		public string clean_rate { get; set; }
		public string difference { get; set; }
		public string grain_size { get; set; }
		public string IO_group_id { get; set; }
		public string IO_group_name { get; set; }
		public string keep_target { get; set; }
	}
}
"@
Add-Type -TypeDefinition $source