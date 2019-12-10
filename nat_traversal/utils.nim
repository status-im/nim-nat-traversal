import macros

# https://github.com/nim-lang/Nim/issues/4441#issuecomment-230441949
macro importConst*(cname: untyped, cheader: string, ctype: untyped): untyped =
  # dumpAstGen:
    # var cnameVar {.importc: "cname", header: "cheader".}: ctype
    # let cname* = cnameVar
  result = newStmtList(
    newNimNode(nnkVarSection).add(
      newIdentDefs(
        newNimNode(nnkPragmaExpr).add(
          newIdentNode($cname & "Var"),
          newNimNode(nnkPragma).add(
            newColonExpr(newIdentNode("importc"), newStrLitNode($cname)),
            newColonExpr(newIdentNode("header"), newStrLitNode($cheader))
          )
        ),
        newIdentNode($ctype),
        newEmptyNode()
      )
    ),
    newNimNode(nnkLetSection).add(
      newIdentDefs(
        postfix(newIdentNode($cname), "*"),
        newEmptyNode(),
        newIdentNode($cname & "Var")
      )
    )
  )
