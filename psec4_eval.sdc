
 
# WARNING: Expected ENABLE_CLOCK_LATENCY to be set to 'ON', but it is set to 'OFF'
#          In SDC, create_generated_clock auto-generates clock latency
#
# ------------------------------------------
#
# Create generated clocks based on PLLs

#
# ------------------------------------------


# Original Clock Setting Name: master_clock0
create_clock -period "8.000 ns" \
					[get_ports master_clock]

#create_clock -period "25.000 ns" \
					-name {clk40M}
				 
#create_clock -period 320MHz -name {xCLK}
					
create_clock -period 4MHz 	[get_ports asic_RDclk1]
					
create_clock -period 4MHz 	[get_ports asic_RDclk2]

derive_pll_clocks -use_tan_name

derive_clock_uncertainty 
# ---------------------------------------------

# ** Clock Latency
#    -------------

# ** Clock Uncertainty
#    -----------------

# ** Multicycles
#    -----------
# ** Cuts
#    ----

# ** Input/Output Delays
#    -------------------




# ** Tpd requirements
#    ----------------

# ** Setup/Hold Relationships
#    ------------------------

# ** Tsu/Th requirements
#    -------------------


# ** Tco/MinTco requirements
#    -----------------------



# ---------------------------------------------

