# test-on-save.nvim

Place cursor at a unit test of your choice, call command 'AttachTestMethod'. Then on each consecutive save, this marked unit test will run in the background. If it failed, the output, including the stacktrace will be sent to the quickfix list. If it pass, a notification will be shown.
