function find_hashtags(line)
  matched_phrases = SubString[]
  references = SubString[]
  reg = r"(#\w+)|(#\[[\w|\s]+\])|(@\w+)"i  # eigher a series of characters without white-space or anything inside [] or references identified by @somename
  offset = 1
  m = match(reg, line, offset)
  while m != nothing
    captures = m.captures
    if captures[1] != nothing
      push!(matched_phrases, captures[1][2:end])
    elseif captures[2] != nothing
      push!(matched_phrases, captures[2][3:end-1])
    elseif captures[3] != nothing
      push!(references, captures[3][2:end])
    end
    offset = m.offset + 1
    m = match(reg, line, offset)
  end
  return matched_phrases, references
end

function word_stems(words::Array{SubString})
  td = TokenDocument(words)
  stem!(td)
  return td.tokens
end

"""
Update your knowledge graph.

"""
function update!(maindb::SQLite.DB, inputfile::AbstractString)  
  for line in eachline(inputfile)
    line = lstrip(line)
    if startswith(line, "*")  # if this is a proposition
      # Check for hash-tagged words 
      nodes, refs = find_hashtags(line)
      if length(nodes) != nothing
        stems = word_stems(nodes)
        # populate tables
        refs = join(refs, ";")
        add_proposition!(maindb, line, nodes, stems, refs)
      end
    end
  end
end

"Copy the bibtex entry from the original file to the programs central file"
function copy_bibentry()
end