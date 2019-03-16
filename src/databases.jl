
function create_bibfile(savelocation)
  bibfile = joinpath(savelocation, "internalbibtex.bib")
  if isfile(bibfile)
    return bibfile
  end
  open(bibfile, "w")
  return bibfile
end

function load_database(savelocation)
  maindb = sqlite.DB(joinpath(savelocation, "notes2graphdb.sqlite"))
  return maindb
end

function initialize_database(savelocation)
  maindb = sqlite.DB(joinpath(savelocation, "notes2graphdb.sqlite"))
  # t1 is a table that keeps a list of all nodes, i.e. concepts
  stmt = "CREATE TABLE IF NOT EXISTS t1 (nodeid INTEGER NOT NULL UNIQUE, nodename TEXT NOT NULL UNIQUE COLLATE NOCASE, PRIMARY KEY (nodeid, nodename))"
  sqlite.query(maindb, stmt)

  # t2 is a table that keeps a list of descriptions and references for each node or relation
  stmt = "CREATE TABLE IF NOT EXISTS t2 (descrid INTEGER NOT NULL UNIQUE PRIMARY KEY, descr TEXT NOT NULL UNIQUE COLLATE NOCASE, ref TEXT)"
  sqlite.query(maindb, stmt)

  # t3 is a table that keeps a list of associations between node ids and description ids
  stmt = "CREATE TABLE IF NOT EXISTS t3 (nodeid INTEGER NOT NULL, descrid INTEGER NOT NULL, PRIMARY KEY (nodeid, descrid))"
  sqlite.query(maindb, stmt)

  # t4 is a table that keeps a list of associations between related node ids
  stmt = "CREATE TABLE IF NOT EXISTS t4 (nodeid INTEGER NOT NULL, relatedid INTEGER NOT NULL, PRIMARY KEY (nodeid, relatedid))"
  sqlite.query(maindb, stmt)

  # t5 is a table that keeps a list of hierarchies between node ids.
  stmt = "CREATE TABLE IF NOT EXISTS t5 (nodeid INTEGER NOT NULL, upid INTEGER NOT NULL, PRIMARY KEY (nodeid, upid))"
  sqlite.query(maindb, stmt)

  # t6 is a table that keeps a list of all the derived words for each stem in the table 1 as `nodename`
  stmt = "CREATE TABLE IF NOT EXISTS t6 (nodeid INTEGER NOT NULL, derivative TEXT NOT NULL COLLATE NOCASE, PRIMARY KEY (nodeid, derivative))"
  sqlite.query(maindb, stmt)

  return maindb
end

function add_t1!(maindb::SQLite.DB, nodename)
  nodeid = table_length(maindb, "t1") + 1
  nodename = replace(nodename, "'" => "''")
  try 
    stmt = "INSERT INTO t1 (nodeid, nodename) VALUES ($nodeid, '$nodename')"
    sqlite.query(maindb, stmt)
  catch
    stmt = "SELECT nodeid FROM t1 WHERE nodename = '$nodename' "
    nodeid = DataFrame(sqlite.query(maindb, stmt))[1,1]
    # nodeid -= 1
  end
  return nodeid
end

function add_t2!(maindb::SQLite.DB, descr, ref)
  descr = replace(descr, "'" => "''")
  stmt = "INSERT OR IGNORE INTO t2 (descr, ref) VALUES ('$descr', '$ref')"
  sqlite.query(maindb, stmt)
  descrid = DataFrame(sqlite.query(maindb, "SELECT MAX(descrid) FROM t2"))[1,1]
  return descrid
end

function add_t3!(maindb::SQLite.DB, nodeid::Integer, descrid::Integer)
  stmt = "INSERT OR IGNORE INTO t3 (nodeid, descrid) VALUES ($nodeid, $descrid)"
  sqlite.query(maindb, stmt)
end

function add_t4!(maindb::SQLite.DB, nodeid::Integer, relatedid::Integer)
  stmt = "INSERT OR IGNORE INTO t4 (nodeid, relatedid) VALUES ($nodeid, $relatedid)"
  sqlite.query(maindb, stmt)
end

function add_t5!(maindb::SQLite.DB, nodeid::Integer, upid::Integer)
  stmt = "INSERT OR IGNORE INTO t5 (nodeid, upid) VALUES ($nodeid, $upid)"
  sqlite.query(maindb, stmt)
end

function add_t6!(maindb::SQLite.DB, nodeid::Integer, derivative)
  derivative = replace(derivative, "'" => "''")
  stmt = "INSERT OR IGNORE INTO t6 (nodeid, derivative) VALUES ($nodeid, '$derivative')"
  sqlite.query(maindb, stmt)
end

"populate all tables"
function add_proposition!(maindb::SQLite.DB, proposition, nodes, stems, refs)
  nnodes = length(nodes)
  all_nodeids = Array{Integer}(undef, nnodes)
  for nn in 1:nnodes
    nodeid = add_t1!(maindb, stems[nn])
    all_nodeids[nn] = nodeid
    if stems[nn] != nodes[nn]
      add_t6!(maindb, nodeid, nodes[nn])
    end
    descrid = add_t2!(maindb, proposition, refs)
    add_t3!(maindb, nodeid, descrid)
  end
  if length(all_nodeids) > 1
    combs = combinations(all_nodeids, 2)
    for comb in combs
      add_t4!(maindb, comb[1], comb[2])
    end
  end
end

# TODO update t5

function table_length(maindb::SQLite.DB, tablename)
  # nrows = sqlite.execute!(maindb, "SELECT Count(1) FROM $tablename")
  nrows = DataFrame(sqlite.query(maindb, "SELECT Count(1) FROM $tablename"))[1,1]
  return nrows
end

## Functions to retrieve information about a concept##

function derivatives(maindb, nodeid)
  stmt = "SELECT derivative FROM t6 WHERE nodeid = $nodeid"
  result = DataFrame(sqlite.query(maindb, stmt))
  if size(result)[1] == 0
    return ""
  else
    ddd = result[1]
    return join(ddd, ", ")
  end
end

function find_nodeid(maindb, query)
  stmt = "SELECT nodeid FROM t1 WHERE nodename = '$query'"
  result = DataFrame(sqlite.query(maindb, stmt))
  if size(result)[1] == 0 # if not found search t6
    stmt = "SELECT nodeid FROM t6 WHERE derivative = '$query'"
    result = DataFrame(sqlite.query(maindb, stmt))
    if size(result)[1] == 0
      @info "Query is not in the database"
      return
    end
  end
  nodeid = result[1,1]
  return nodeid
end

function related_concepts(maindb, nodeid)
  stmt = "SELECT relatedid FROM t4 WHERE nodeid = $nodeid"
  result = DataFrame(sqlite.query(maindb, stmt))
  if size(result)[1] == 0
    return ""
  else
    nmatches = length(result[1])
    nodenames = Array{String}(undef, nmatches)
    for m in 1:nmatches
      idd = result[1][m]
      stmt = "SELECT nodename FROM t1 WHERE nodeid = $idd"
      match = DataFrame(sqlite.query(maindb, stmt))[1,1]
      nodenames[m] = match
    end
    return join(nodenames, ", ")
  end
end

function find_descrid(maindb, nodeid)
  stmt = "SELECT descrid FROM t3 WHERE nodeid = $nodeid"
  result = DataFrame(sqlite.query(maindb, stmt))[1]
  return result
end

function descriptions(maindb, nodeid)
  descrids = find_descrid(maindb, nodeid)
  ndescrs = length(descrids)
  descrs = Array{String}(undef, ndescrs)
  refs = Array{String}(undef, ndescrs)
  for ind in 1:ndescrs
    stmt = "SELECT descr, ref FROM t2 WHERE descrid = $(descrids[ind])"
    result = DataFrame(sqlite.query(maindb, stmt))
    descrs[ind] = result[1,1]
    refs[ind] = result[1,2]
  end
  return descrs, refs
end

"Returns descrids of descriptions of relations between node1id and node2id"
function relationid(maindb, node1id::Integer, node2id::Integer)
  stmt = "SELECT descrid FROM t3 WHERE nodeid = $node1id INTERSECT SELECT descrid FROM t3 WHERE nodeid = $node2id"
  results = DataFrame(sqlite.query(maindb, stmt))[1]
  return results
end

function relation_descr(maindb, node1::AbstractString, node2::AbstractString)
  node1id = find_nodeid(maindb, node1)
  node2id = find_nodeid(maindb, node2)
  relationids = relationid(maindb, node1id, node2id)
  ndescr = length(relationids)
  descrs = Array{Tuple}(undef, ndescr)
  for nn in 1:ndescr
    descr = descriptions(maindb, relationids[nn])
    descrs[nn] =  descr
  end
  return descrs
end