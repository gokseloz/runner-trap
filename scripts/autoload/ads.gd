extends Node
## Rewarded ads. There is no ad SDK yet (AdMob comes with the Play release),
## so rewards are granted right away.


## Shows a rewarded ad and calls on_reward once the player has earned it.
## Players who bought ad removal get the reward without an ad.
func show_rewarded(on_reward: Callable) -> void:
	on_reward.call()
