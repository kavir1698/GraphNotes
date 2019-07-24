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

## ArgParse
function parse_commandline()
  settings = ap.ArgParseSettings(
                version="0.1",
                prog="Notes2graph",
                description="Create a graph from your notes written in Pandoc format. Each note to be considered should have a bullet point (*). Moreover, keywords should be tagged with a hash (#). If you want to tag compound words that have spaces between them, wrap them in square brackets. E.g. #[compound word].",
                add_version=true,
                add_help=true,
                autofix_names=true,
                )

  argtable = ap.add_arg_table(
                settings,
                "savelocation",
                Dict(
                  :help => "Path to a directory that keeps the database file of Notes2Graph. If the first time running the program, the database file will be saved in this directory.",
                  :required => true,
                  :arg_type => String,
                ),
                ["--notefile", "-n"],
                Dict(
                  :help => "Add your notes to the graph. Supply notes file.",
                  :arg_type => String
                ),
                ["--reffile", "-r"],
                Dict(
                  :help => "If a notefile is mentioned, add a reference file in the form of a bibtex file. This option is not implemented yet.",
                  :arg_type => String
                ),
                ["--descriptions", "-d"],
                Dict(
                  :help => "Shows all the available descriptions for the provided concept. To write concepts with multiple words and spaces, wrap them in double quotations (\")."
                ),
                ["--related", "-t"],
                Dict(
                  :help => "Shows all related concepts. If you want to know more about the relation between each pair of concepts, use -r1 and -r2.",
                  :action => :store_true
                ),
                "--r1",
                Dict(
                  :help => "The first concept of two concepts, to show their relation."
                ), 
                "--r2",
                Dict(
                  :help => "The second concept of two concepts, to show their relation."
                )
                )

  parsed_args = ap.parse_args(ARGS, settings, as_symbols=true)
  return parsed_args
end

"Print a list in a readable format"
function pretty_print(yourlist)
  for (index, item) in enumerate(yourlist)
    print("$index  ")
    println(item)
  end
end

function main()
  parsed_args = parse_commandline()
  
  savelocation = parsed_args[:savelocation]

  # load/create databases
  dbfile = joinpath(savelocation, "notes2graphdb.sqlite")
  bibfile = joinpath(savelocation, "internalbibtex.bib")
  if !isfile(dbfile) # create tables to be filled
    bibfile = create_bibfile(savelocation)
    maindb = initialize_database(savelocation);
  else # load the tables from file
    maindb = load_database(savelocation)
  end

  if parsed_args[:notefile] != nothing
    update!(maindb, parsed_args[:notefile])
  else
    if parsed_args[:descriptions] != nothing
      nodeid = find_nodeid(maindb, parsed_args[:descriptions])
      descrs, refs = descriptions(maindb, nodeid)
      println("# Descriptions for $(parsed_args[:descriptions]):")
      pretty_print(descrs)
      println("# References:")
      pretty_print(refs)
      if parsed_args[:related] == true
        relatedconcepts = related_concepts(maindb, nodeid)
        println("# Related concepts:")
        println(relatedconcepts)
      end
    end
    if parsed_args[:r1] != nothing && parsed_args[:r2] != nothing
      descrs = relation_descr(maindb,  parsed_args[:r1], parsed_args[:r2])
      println("# Relations between $(parsed_args[:r1]) and $(parsed_args[:r2]):")
      pretty_print([i[1] for i in descrs])
      println("# References for the raltions:")
      pretty_print([i[2] for i in descrs])
    end
  end
  # parse text files
  # parse bibtex files and add entries to the databases internal bibtex
  # get stems of words
  # fill tables
  # call information
  # edit entries in tables
  # pretty print results
end