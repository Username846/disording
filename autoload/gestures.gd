extends Node
## Factory and shared tuning for GestureRecognizer (PLAN.md §5).


func make_recognizer() -> GestureRecognizer:
	return GestureRecognizer.new()
