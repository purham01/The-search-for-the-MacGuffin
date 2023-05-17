extends Control

func _ready():
	SoundManager.stop("EndingMusic")

func _on_Language_button_up():
	if TranslationServer.get_locale() == "hr":
		TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("hr")
