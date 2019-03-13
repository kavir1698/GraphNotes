
function create_bibfile(savelocation)
  bibfile = joinpath(savelocation, "internalbibtex.bib")
  open(bibfile, "w")
  return bibfile
end

function initialize_databases()
  # t1 is a table that keeps a list of all nodes, i.e. concepts
  t1 = table([0], ["noname"], names=[:nodeid, :nodename], pkey=[:nodeid, :nodename])
  # t2 is a table that keeps a list of descriptions and references for each node or relation
  t2 = table([0], ["nodescr"], [["noref"]], names=[:descrid, :descr, :ref], pkey=[:descrid, :descr])
  # t3 is a table that keeps a list of associations between node ids and description ids
  t3 = table([0], [0], names=[:nodeid, :descrid], pkey=[:nodeid, :descrid])
  # t4 is a table that keeps a list of associations between related node ids
  t4 = table([0], [0], names=[:nodeid, :relatedid], pkey=[:nodeid, :relatedid])
  # t5 is a table that keeps a list of hierarchies between node ids.
  t5 = table([0], [0], names=[:nodeid, :upid], pkey=[:nodeid, :upid])
  return (t1=t1, t2=t2, t3=t3, t4=t4, t5=t5)
end

function save_empty_databases(tables::NamedTuple, savelocation)
  for key in keys(tables)
    save(tables[key], joinpath(savelocation, string(key)))
  end
end

function load_databases(savelocation)
  t1 = load(joinpath(savelocation, "t1"))
  t2 = load(joinpath(savelocation, "t2"))
  t3 = load(joinpath(savelocation, "t3"))
  t4 = load(joinpath(savelocation, "t4"))
  t5 = load(joinpath(savelocation, "t5"))
  return (t1=t1, t2=t2, t3=t3, t4=t4, t5=t5)
end
