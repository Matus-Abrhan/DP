
Number of events : 2
Number of events that should be refused : 1
Number of errors during the execution : 0

Lines to add to func_test.py at time of writing :
  ("TFunc/exASTD/test_synchronization_not_executing_action_before_possible/synchronization.iastd", "TFunc/exASTD/test_synchronization_not_executing_action_before_possible/in.txt", 2, 1, 0),
  ("TFunc/exASTD/test_synchronization_not_executing_action_before_possible/quantified_synchronization.iastd", "TFunc/exASTD/test_synchronization_not_executing_action_before_possible/in.txt", 2, 1, 0),

This test illustrate that the synchronization should check if both sub-astds can accept the transition
before executing their respective actions during a synchronized transition. The execution of the actions
does not affect iASTD internal environment (attributes, parameters, etc.) but it can have side effect on
external environment, like sending a http request to a server of logging something in a DB. In this case,
it writes over a global ref in the functions.ml module.

Detailed walkthrough of synchronization.iastd :
e1 is received (synchronized label)
  We try it on the first astd, which accepts it so we execute its action.
  We try it on the second astd, which refuses it due to its guard.
  We then reject all results from both execution, but we can't rollback the changing of the ref variable
  in functions.ml.
e1 fails, like it should.

e2 is received (not synchronized label)
  We try to execute it on the first astd but it can't accept the event because the guard expects the 
  global variable in functions.ml to have its initial value. It should have its initial value because no
  action should have been executed when we received e1, but it is not the case... This is the bug.
e2 fails, but it should pass.


quantified_synchronization.iastd show the same problem but with the iteration over the domain of a quantified variable.


See issue #91 for more details.
