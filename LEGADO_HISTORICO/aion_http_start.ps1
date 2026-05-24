$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:AION_HTTP_TOKEN    = 'dd8d91a5bf264a7aa303a42aab4125ca'
$env:AION_WATCHER_STATE = 'ACTIVE'
$env:AION_ROOT          = 'D:\TEIA_CLAUDE_AWAKENING'
$env:AION_QUEUE         = 'D:\TEIA_CLAUDE_AWAKENING\aion_restore_queue.jsonl'
$env:AION_LOGS          = 'D:\TEIA_CLAUDE_AWAKENING\logs'
& 'D:\TEIA_CLAUDE_AWAKENING\AION-Local-Http.ps1' -Port 8123 -Root 'D:\TEIA_CLAUDE_AWAKENING' -QueuePath 'D:\TEIA_CLAUDE_AWAKENING\aion_restore_queue.jsonl' -LogPath 'D:\TEIA_CLAUDE_AWAKENING\logs\restore_watcher.log'
