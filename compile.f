+incdir+./
+incdir+./btb
+incdir+./fetch
+incdir+./decode
+incdir+./execute
+incdir+./memory
+incdir+./writeback
+incdir+./pipeline

define.vh

# BTB
btb/btb.v
btb/btb_read.v
btb/btb_write.v
btb/dynamic_branch_predictor.v

# Fetch
fetch/pc.v
fetch/pc_update.v
fetch/fetch_stage.v

# Decode
decode/register_file.v
decode/decode_controller.v
decode/decode_stage.v

# Execute
excute/alu_top.v
excute/pc_jump.v
excute/execute_stage.v

# Memory
memory/data_mem.v
memory/mem_stage.v

# Writeback
writeback/writeback_stage.v

# Pipeline Registers
pipeline/if_id_pipeline.v
pipeline/id_ex_pipeline.v
pipeline/ex_mem_pipeline.v
pipeline/mem_wb_pipeline.v

# Hazard + forwarding
forwarding_unit.v
hazard_unit.v

# Top and TB
rv32i_core.v
rv32i_core_tb.v

