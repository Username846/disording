class_name BundleRequest
extends RefCounted
## Handle for an in-flight bundle download. await request.done, or poll progress/finished.

signal done(bundle: AudioBundle)

var id := ""
var progress := 0.0
var finished := false
var error := ""
var bundle: AudioBundle


func finish(result: AudioBundle, err: String = "") -> void:
	if finished:
		return
	bundle = result
	error = err
	progress = 1.0
	finished = true
	done.emit(result)
