extends Node
## Rewarded ads through AdMob (Poing Studios plugin).
## At startup it asks for consent where the law requires it (UMP: EEA, UK, Switzerland),
## then keeps one rewarded ad loaded. Without the native plugin (desktop, editor,
## headless tests) rewards are granted right away.

## Fires once consent info is known, so settings can show the privacy options button.
signal consent_updated

const REWARDED_UNIT_ID := "ca-app-pub-4493910201796782/1833554825"
## Google's sample rewarded unit: debug builds never request real ads.
const TEST_REWARDED_UNIT_ID := "ca-app-pub-3940256099942544/5224354917"
const PLUGIN_SINGLETON := "PoingGodotAdMob"

var _enabled := false
var _initialized := false
var _loading := false
var _rewarded_ad: RewardedAd


func _ready() -> void:
	_enabled = Engine.has_singleton(PLUGIN_SINGLETON)
	if _enabled:
		UserMessagingPlatform.consent_information.update(
			ConsentRequestParameters.new(), _on_consent_info_updated, _on_consent_info_failed
		)


## Shows a rewarded ad and calls on_reward once the player has earned it.
## Players who bought ad removal get the reward without an ad, and so does everyone
## when no ad is ready (offline, no fill), so a missing ad never blocks the continue.
func show_rewarded(on_reward: Callable) -> void:
	if GameState.ads_removed or _rewarded_ad == null:
		on_reward.call()
		_load_rewarded()
		return
	var ad := _rewarded_ad
	_rewarded_ad = null
	# Lambdas capture locals by value, so the flag lives in an array.
	var earned := [false]
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void: earned[0] = true
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		_load_rewarded()
		if earned[0]:
			on_reward.call()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		_load_rewarded()
		on_reward.call()
	ad.show(reward_listener)


## True where the player must be able to change their consent choice (EEA, UK, Switzerland).
func is_privacy_options_required() -> bool:
	return _enabled and (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)


func show_privacy_options() -> void:
	if _enabled:
		UserMessagingPlatform.show_privacy_options_form(func(_error: FormError) -> void: _start_ads())


func _on_consent_info_updated() -> void:
	var consent := UserMessagingPlatform.consent_information
	if consent.get_is_consent_form_available() and consent.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void: form.show(func(_error: FormError) -> void: _start_ads()),
			func(_error: FormError) -> void: _start_ads()
		)
	else:
		_start_ads()


## Offline or UMP error: a choice stored on an earlier launch may still allow ads.
func _on_consent_info_failed(_error: FormError) -> void:
	_start_ads()


func _start_ads() -> void:
	consent_updated.emit()
	if _initialized or not _can_request_ads():
		return
	_initialized = true
	MobileAds.initialize()
	_load_rewarded()


func _can_request_ads() -> bool:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	return status == ConsentInformation.ConsentStatus.OBTAINED or status == ConsentInformation.ConsentStatus.NOT_REQUIRED


func _load_rewarded() -> void:
	if not _initialized or GameState.ads_removed or _loading or _rewarded_ad != null:
		return
	_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading = false
		_rewarded_ad = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void: _loading = false
	var unit_id := TEST_REWARDED_UNIT_ID if OS.is_debug_build() else REWARDED_UNIT_ID
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), callback)
