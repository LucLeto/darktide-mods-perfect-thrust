local mod = get_mod("PerfectThrust")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "indicator_group",
                type = "group",
                tooltip = "indicator_group_tooltip",
                sub_widgets = {
                    {
                        setting_id = "display_mode",
                        type = "dropdown",
                        default_value = "progress",
                        tooltip = "display_mode_tooltip",
                        options = {
                            { text = "display_mode_progress", value = "progress" },
                            { text = "display_mode_ready_only", value = "ready_only" }
                        }
                    },
                    {
                        setting_id = "timing_mode",
                        type = "dropdown",
                        default_value = "predicted",
                        tooltip = "timing_mode_tooltip",
                        options = {
                            { text = "timing_mode_predicted", value = "predicted" },
                            { text = "timing_mode_confirmed", value = "confirmed" }
                        }
                    },
                    {
                        setting_id = "ring_radius",
                        type = "numeric",
                        default_value = 32,
                        range = { 12, 150 },
                        decimals_number = 0,
                        step_size_value = 1,
                        tooltip = "ring_radius_tooltip"
                    },
                    {
                        setting_id = "ring_thickness",
                        type = "numeric",
                        default_value = 3,
                        range = { 1, 10 },
                        decimals_number = 0,
                        step_size_value = 1,
                        tooltip = "ring_thickness_tooltip"
                    },
                    {
                        setting_id = "offset_x",
                        type = "numeric",
                        default_value = 0,
                        range = { -960, 960 },
                        decimals_number = 0,
                        step_size_value = 1,
                        tooltip = "offset_x_tooltip"
                    },
                    {
                        setting_id = "offset_y",
                        type = "numeric",
                        default_value = 0,
                        range = { -540, 540 },
                        decimals_number = 0,
                        step_size_value = 1,
                        tooltip = "offset_y_tooltip"
                    },
                    {
                        setting_id = "ring_opacity",
                        type = "numeric",
                        default_value = 100,
                        range = { 20, 100 },
                        decimals_number = 0,
                        step_size_value = 5,
                        tooltip = "ring_opacity_tooltip"
                    },
                    {
                        setting_id = "ready_pulse",
                        type = "checkbox",
                        default_value = true,
                        tooltip = "ready_pulse_tooltip"
                    },
                    {
                        setting_id = "debug_logging",
                        type = "checkbox",
                        default_value = false,
                        tooltip = "debug_logging_tooltip"
                    }
                }
            }
        }
    }
}
