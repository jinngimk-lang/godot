extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/inspection/inspection_controller.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing deterministic InspectionController")
		return failures
	var inspection = load(path).new({"sensitivity": 0.006, "follow_rate": 18.0})
	inspection.begin()
	inspection.drag(42.0, 0.016)
	inspection.tick(0.016)
	if inspection.get_yaw() <= 0.0:
		failures.append("inspection drag should rotate product yaw")
	var active_yaw: float = inspection.get_yaw()
	inspection.end()
	inspection.drag(60.0, 0.016)
	inspection.tick(0.016)
	if inspection.get_target_yaw() > active_yaw + 0.01:
		failures.append("inspection drag must be ignored after RMB ownership ends")
	inspection.reset()
	if not is_equal_approx(inspection.get_yaw(), 0.0) or not is_equal_approx(inspection.get_target_yaw(), 0.0):
		failures.append("inspection reset must restore neutral yaw")
	return failures
