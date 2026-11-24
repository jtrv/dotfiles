def src: if type == "array" then join("") else . end;
(.metadata.kernelspec.language // .metadata.language_info.name // "") as $lang
| .cells[]
| if .cell_type == "markdown" then .source | src
  elif .cell_type == "code" then
    "```\($lang)\n\(.source | src)\n```"
    + ([.outputs[]? | (.text // .data["text/plain"] // empty) | src] | if length > 0 then "\n```\n\(join(""))\n```" else "" end)
  else empty end
| . + "\n"
