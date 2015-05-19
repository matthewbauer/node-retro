{
    "variables": {
        "module_name": "retro",
        "module_path": "./lib/binding/"
    },
    "targets": [
        {
            "target_name": "<(module_name)",
            "sources": ["binding.cc"],
            "include_dirs": [
                "<!(node -p -e \"require('path').dirname(require.resolve('nan'))\")",
                "<!(node -e \"require('node-arraybuffer')\")"
            ]
        },
        {
            "target_name": "action_after_build",
            "type": "none",
            "dependencies": ["<(module_name)"],
            "copies": [
                {
                    "files": ["<(PRODUCT_DIR)/<(module_name).node"],
                    "destination": "<(module_path)"
                }
            ]
        }
    ]
}
