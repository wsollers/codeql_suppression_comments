/**
 * @name Custom Suppression Example
 * @description Suppresses buffer overflow alerts in test files
 * @kind problem
 * @id cpp/custom-buffer-overflow-suppression
 * @problem.severity warning
 */

 import cpp

 from FunctionCall call
 where
   call.getTarget().getName() = "strcpy" and
   call.getFile().getRelativePath().matches("%test%")
 select call, "Buffer overflow in test code (custom suppression)"