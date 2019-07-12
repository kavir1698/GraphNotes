import os
import db_sqlite
import strutils  # for working with strings
import itertools  # for combinations function
import nre # regex library

# var allparams = commandLineParams()

# remember to close database maindb.close()

proc create_bibfile(savelocation: string): string = 
  var bibfile = joinpath(savelocation, "internalbibtex.bib")
  if existsFile(bibfile):
    return

  else:
    writeFile(bibfile, "")
    return


proc load_database(savelocation: string): db_sqlite.DbConn =
  var filename: string = joinpath(savelocation, "notes2graphdb.sqlite")
  var maindb = db_sqlite.open(filename, "", "", "")  ## user, password, database name can be empty. These params are not used on db_sqlite module.
  return maindb


proc initialize_database(savelocation: string): db_sqlite.DbConn =
  var maindb: db_sqlite.DbConn = db_sqlite.open(joinpath(savelocation, "notes2graphdb.sqlite"), "", "", "")
  # t1 is a table that keeps a list of all nodes, i.e. concepts
  var stmt: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t1 (nodeid INTEGER NOT NULL UNIQUE, nodename TEXT NOT NULL UNIQUE COLLATE NOCASE, PRIMARY KEY (nodeid, nodename))"
  maindb.exec(stmt)
  # t2 is a table that keeps a list of descriptions and references for each node or relation
  var stmt2: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t2 (descrid INTEGER NOT NULL UNIQUE PRIMARY KEY, descr TEXT NOT NULL UNIQUE COLLATE NOCASE, ref TEXT)"
  maindb.exec(stmt2)
  # t3 is a table that keeps a list of associations between node ids and description ids
  var stmt3: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t3 (nodeid INTEGER NOT NULL, descrid INTEGER NOT NULL, PRIMARY KEY (nodeid, descrid))"
  maindb.exec(stmt3)
  # t4 is a table that keeps a list of associations between related node ids
  var stmt4: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t4 (nodeid INTEGER NOT NULL, relatedid INTEGER NOT NULL, PRIMARY KEY (nodeid, relatedid))"
  maindb.exec(stmt4)
  # t5 is a table that keeps a list of hierarchies between node ids.
  var stmt5: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t5 (nodeid INTEGER NOT NULL, upid INTEGER NOT NULL, PRIMARY KEY (nodeid, upid))"
  maindb.exec(stmt5)
  # t6 is a table that keeps a list of all the derived words for each stem in the table 1 as `nodename`
  var stmt6: SqlQuery = sql"CREATE TABLE IF NOT EXISTS t6 (nodeid INTEGER NOT NULL, derivative TEXT NOT NULL COLLATE NOCASE, PRIMARY KEY (nodeid, derivative))"
  maindb.exec(stmt6)
  return maindb


proc dblen(maindb: db_sqlite.DbConn, tablename: string): int=
  var cmd: string = "SELECT Count(*) FROM $1" % tablename
  var counter: int = 0
  for row in maindb.fastRows(sql(cmd)):
    counter += 1

  return counter



proc dblen(maindb: db_sqlite.DbConn, query: SqlQuery): int=
  var counter: int = 0
  for row in maindb.fastRows(query):
    counter += 1

  return counter


proc add_t1(maindb: db_sqlite.DbConn, nodename: string): int =
  var nodeid: int = dblen(maindb, "t1")
  # var nodename: string = replace(nodename, "'", "''")
  var nodename2: string = dbQuote(nodename)
  # if node name does not exist
  try:
    var stmt2: string = "INSERT INTO t1 (nodeid, nodename) VALUES ($1, $2)" % [$nodeid, nodename2]
    maindb.exec(sql(stmt2))
    return nodeid

  except:
    var stmt3: string = "SELECT nodeid FROM t1 WHERE nodename = $1" % nodename2
    nodeid = dblen(maindb, sql(stmt3))
    return nodeid



proc add_t2(maindb: db_sqlite.DbConn, descr: string, reff: string): int =
  # var descr: string = replace(descr, "'", "''")
  var descr: string = dbQuote(descr)  # replace single quote with ''
  var cmd: string = "INSERT OR IGNORE INTO t2 (descr, ref) VALUES ($1, '$2')" % [descr, reff]
  var stmt: SqlQuery = sql(cmd)
  maindb.exec(stmt)
  var descrrow: string = maindb.getValue(sql"SELECT MAX(descrid) FROM t2")
  var descrid: int = parseInt(descrrow)
  return descrid


proc add_t3(maindb: db_sqlite.DbConn, nodeid: int, descrid: int)=
  var cmd: string = "INSERT OR IGNORE INTO t3 (nodeid, descrid) VALUES ($1, $2)" % [$nodeid, $descrid]
  var stmt: SqlQuery = sql(cmd)
  maindb.exec(stmt)


proc add_t4(maindb: db_sqlite.DbConn, nodeid: int, relatedid: int)=
  var cmd: string = "INSERT OR IGNORE INTO t4 (nodeid, relatedid) VALUES ($1, $2)" % [$nodeid, $relatedid]
  var stmt: SqlQuery = sql(cmd)
  maindb.exec(stmt)


# proc add_t5(maindb: db_sqlite.DbConn, nodeid: int, upid: int)=
#   var cmd: string = "INSERT OR IGNORE INTO t5 (nodeid, upid) VALUES ($nodeid, $upid)" % [$nodeid, $upid]
#   var stmt: SqlQuery = sql(cmd)
#   maindb.exec(stmt)


proc add_t6(maindb: db_sqlite.DbConn, nodeid: int, derivative: string)=
  var derivative: string = dbQuote(derivative)
  var cmd: string = "INSERT OR IGNORE INTO t6 (nodeid, derivative) VALUES ($1, $2)" % [$nodeid, derivative]
  var stmt: SqlQuery = sql(cmd)
  maindb.exec(stmt)


proc add_proposition(maindb: db_sqlite.DbConn, proposition: string, nodes: seq, stems: seq, refs: seq): int=
  ## Populate all tables
  var nnodes: int = nodes.len
  var all_nodeids = newSeq[int](nnodes)
  for ni in 0..<nnodes:
    all_nodeids[ni] = ni+1

  for nn in 0..<nnodes:
    var nodeid: int = add_t1(maindb, stems[nn])
    all_nodeids[nn] = nodeid
    if stems[nn] != nodes[nn]:
      add_t6(maindb, nodeid, nodes[nn])

    for rff in 0..<refs.len:
      var descrid: int = add_t2(maindb, proposition, refs[rff])
      add_t3(maindb, nodeid, descrid)


  if nnodes > 1:
    for comb in combinations(all_nodeids, 2):
      add_t4(maindb, comb[0], comb[1])
  
  return 0



proc derivatives(maindb: db_sqlite.DbConn, nodeid: int): string =
  ## Returns all the derivatives of the concept with nodeid
  let final: seq[Row] = maindb.getAllRows(sql"SELECT derivative FROM t6 WHERE nodeid = ?", $nodeid)
  let ll: int = final.len
  if ll == 0:
    return ""

  else:
    var k:seq[string] = newSeq[string](ll)
    for i in 0..<ll: k[i] = final[i][0]
    return join(k, ", ")



proc find_nodeid(maindb: db_sqlite.DbConn, query: string): int =
  ## Returns node ID of a query
  let final: seq[Row] = maindb.getAllRows(sql"SELECT nodeid FROM t1 WHERE nodename = '?'", query)
  # if not found search t6
  if final.len == 0:
    let final: seq[Row] = maindb.getAllRows(sql"SELECT nodeid FROM t6 WHERE derivative = '?'", query)
    if final.len == 0:
      echo "Query is not in the database"
      return -1

    else:
      var nodeids: string = final[0][0]
      var nodeid: int = parseInt(nodeids)
      return nodeid




proc related_concepts(maindb: db_sqlite.DbConn, nodeid: int): string =
  ## Returns IDs if related nodes to a given ID
  let final: seq[Row] = maindb.getAllRows(sql"SELECT relatedid FROM t4 WHERE nodeid = ?", $nodeid)
  let nmatches: int = final.len
  if nmatches == 0:
    return ""

  else:
    var nodenames: seq[string] = newSeq[string](nmatches)
    for m in 0..<nmatches:
      let idd: int = parseInt(final[0][m])
      var match: string = maindb.getValue(sql"SELECT nodename FROM t1 WHERE nodeid = '?'", idd)
      nodenames[m] = match

    return join(nodenames, ", ")



proc find_descrid(maindb: db_sqlite.DbConn, nodeid: int): seq[Row] =
  let final: seq[Row] = maindb.getAllRows(sql"SELECT descrid FROM t3 WHERE nodeid = ?", nodeid)
  return final


proc descriptions(maindb: db_sqlite.DbConn, nodeid: int): seq[seq[string]] =
  let descrids: seq[Row] = find_descrid(maindb, nodeid)
  let ndescrs: int = descrids.len
  var descrs: seq[string] = newSeq[string](ndescrs)
  var refs: seq[string] = newSeq[string](ndescrs)
  for ind in 0..<ndescrs:
    let final: seq[Row] = maindb.getAllRows(sql"SELECT descr, ref FROM t2 WHERE descrid = ?", $descrids[ind])
    descrs[ind] = final[0][0]
    refs[ind] = result[0][1]

  var rr = @[descrs, refs]
  return rr


proc relationid(maindb: db_sqlite.DbConn, node1id: int, node2id: int): seq[int] =
  ## Returns descrids of descriptions of relations between node1id and node2id
  let final: seq[Row] = maindb.getAllRows(sql"ELECT descrid FROM t3 WHERE nodeid = ? INTERSECT SELECT descrid FROM t3 WHERE nodeid = ?", $node1id, $node2id)
  var k:seq[int] = newSeq[int](final.len)
  for i in 0..<final.len:
    k[i] = parseInt(final[i][0])

  return k


proc relation_descr(maindb: db_sqlite.DbConn, node1: string, node2: string): seq[seq[seq[string]]] =
  let node1id: int = find_nodeid(maindb, node1)
  let node2id: int = find_nodeid(maindb, node2)
  var relationids: seq[int] = relationid(maindb, node1id, node2id)
  let ndescr: int = relationids.len
  var descrs: seq[seq[seq[string]]] =  newSeq[seq[seq[string]]](ndescr)
  for nn in 0..<ndescr:
    var descr: seq[seq[string]] = descriptions(maindb, relationids[nn])
    descrs[nn] = descr

  return descrs


proc find_hashtags(line: string): seq[seq[string]] =
  var matched_phrases: seq[string] = @[]
  var references: seq[string] = @[]
  let reg = re"(#\w+)|(#\[[\w|\s]+\])|(@\w+)"  # either a series of characters without white-space or anything inside [] or references identified by @somename
  var m: seq[string] = line.findAll(reg, 1, int.high)
  for vv in m:
    if startsWith(vv, "#"):
      if startsWith(vv, "#["):
        matched_phrases.add(vv[2..vv.high-1])

      else:
        matched_phrases.add(vv[1..vv.high])


    else:
      references.add(vv[2..vv.high])


  return @[matched_phrases, references]


proc update(maindb: db_sqlite.DbConn, inputfile: string): int =
  ## Update the knowledge graph
  for line in lines(inputfile):
    var line2: TaintedString = strip(line)
    # if this is a proposition
    if line2.startswith("*"): 
      # Check for hash-tagged words 
      var allr: seq[seq[string]] = find_hashtags(line2)
      if allr[0].len > 0:
        # there were hash tags in line
        var nodes: seq[string] = allr[0]
        var refs: seq[string] = allr[1]
        if nodes.len != 0:
          # TODO: install porter stemmer and take word stems
          # stems = word_stems(nodes)
          var stems: seq[string] = nodes
          # var refs2: string = join(refs, ";")
          discard add_proposition(maindb, line2, nodes, stems, refs)  # populate tables
      
  return 0
  
