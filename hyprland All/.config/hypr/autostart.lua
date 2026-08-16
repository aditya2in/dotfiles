-- Extra autostart processes.
o.exec_on_start("sleep 10 && uwsm-app -- /home/adityaws/DOTfiles/scripts/hyprsunset_watch.sh")
o.launch_on_start("brave http://localhost:8384")
o.launch_on_start("sticky")

-- Command Center Startup
o.launch_on_start("ghostty")
o.launch_on_start("brave")
o.launch_on_start("obsidian")


