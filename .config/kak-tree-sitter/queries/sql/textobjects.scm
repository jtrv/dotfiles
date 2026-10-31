; Not from upstream: DerekStride ships none and helix's only covers comments.
; function = a whole statement, class = CREATE TABLE / CTE, parameter = a list item
; (column, constraint, select term, call argument, VALUES entry).

(statement) @function.around

(create_table) @class.around
(create_table (column_definitions) @class.inside)
(cte) @class.around
(cte (statement) @class.inside)

(column_definitions ((column_definition) @parameter.inside . ","? @parameter.around) @parameter.around)
(constraints ((constraint) @parameter.inside . ","? @parameter.around) @parameter.around)
(select_expression ((term) @parameter.inside . ","? @parameter.around) @parameter.around)
(invocation ((term) @parameter.inside . ","? @parameter.around) @parameter.around)
(list ((_) @parameter.inside . ","? @parameter.around) @parameter.around)

(comment) @comment.inside
(comment)+ @comment.around
(marginalia) @comment.inside
(marginalia) @comment.around
