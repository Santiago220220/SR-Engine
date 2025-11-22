package utils;

import Character;
import Character.CharacterFile;
import Note;
import NoteSplash;
import Paths;
import ClientPrefs;
import Song.SwagSong;
import StageData;
import haxe.Json;
import haxe.ds.StringMap;
using StringTools;

class VRAMCache
{
	private static var _loadedThisSession:StringMap<Bool>;

	public static function preloadForSong(song:SwagSong, dad:Character, boyfriend:Character, gf:Character, currentStage:String, stageUI:String, isPixelStage:Bool, dadSkin:String, bfSkin:String):Void
	{
		if (!ClientPrefs.cacheOnGPU || song == null)
			return;

		_loadedThisSession = new StringMap<Bool>();

		var isPixel = (stageUI == 'pixel' || isPixelStage);
		var uiPrefix = isPixel ? 'pixelUI/' : '';
		var uiSuffix = isPixel ? '-pixel' : '';

		cacheGraphic(uiPrefix + 'ready' + uiSuffix);
		cacheGraphic(uiPrefix + 'set' + uiSuffix);
		cacheGraphic(uiPrefix + 'go' + uiSuffix);
		cacheGraphic(uiPrefix + 'sick' + uiSuffix);
		cacheGraphic(uiPrefix + 'good' + uiSuffix);
		cacheGraphic(uiPrefix + 'bad' + uiSuffix);
		cacheGraphic(uiPrefix + 'shit' + uiSuffix);
		
		var comboPrefix = isPixel ? 'pixelUI/num' : 'num';
		for (i in 0...10)
			cacheGraphic(comboPrefix + i + uiSuffix);

		cacheGraphic(Note.defaultNoteSkin + Note.getNoteSkinPostfix());
		cacheGraphic('noteSplashes/noteSplashes' + NoteSplash.getSplashSkinPostfix());
		
		if (isPixel)
			cacheGraphic('pixelUI/NOTE_assets');

		preloadNoteSkin(dadSkin);
		preloadNoteSkin(bfSkin);

		if (song.player1 != null) preloadCharacter(song.player1);
		if (song.player2 != null) preloadCharacter(song.player2);
		if (song.gfVersion != null) preloadCharacter(song.gfVersion);

		if (dad != null && dad.curCharacter != song.player2) preloadCharacter(dad.curCharacter);
		if (boyfriend != null && boyfriend.curCharacter != song.player1) preloadCharacter(boyfriend.curCharacter);
		if (gf != null && gf.curCharacter != song.gfVersion) preloadCharacter(gf.curCharacter);

		if (song.notes != null)
		{
			for (section in song.notes)
			{
				if (section.sectionNotes != null)
				{
					for (note in section.sectionNotes)
					{
						if (note.length > 3 && note[3] != null && Std.isOfType(note[3], String))
						{
							var noteType:String = note[3];
							if (noteType.length > 0)
								cacheGraphic('custom_notetypes/' + noteType);
						}
					}
				}
			}
		}

		preloadStage(currentStage);

		_loadedThisSession = null;
	}

	static function preloadStage(stage:String):Void
	{
		if (stage == null || stage.length == 0) return;

		try {
			var stageFile = StageData.getStageFile(stage);
			if (stageFile != null && stageFile.directory != null && stageFile.directory.length > 0)
			{
				var dir = stageFile.directory;
				if (Paths.imageExists('stages/' + dir + '/stageback'))
					cacheGraphic('stages/' + dir + '/stageback');
				if (Paths.imageExists('stages/' + dir + '/stagefront'))
					cacheGraphic('stages/' + dir + '/stagefront');
				if (Paths.imageExists('stages/' + dir + '/stage_light'))
					cacheGraphic('stages/' + dir + '/stage_light');
				if (Paths.imageExists('stages/' + dir + '/stagecurtains'))
					cacheGraphic('stages/' + dir + '/stagecurtains');
				if (Paths.imageExists('stages/' + dir + '/sky'))
					cacheGraphic('stages/' + dir + '/sky');
			}
		} catch(e:Dynamic) {}
	}

	static function preloadNoteSkin(skin:String):Void
	{
		if (skin == null || skin.length == 0 || skin == 'default') return;

		var normalized = skin;
		if (!normalized.startsWith('noteskins/'))
			normalized = 'noteskins/' + normalized;

		cacheGraphic(normalized);
	}

	static function preloadCharacter(charName:String):Void
	{
		if (charName == null || charName.length == 0) return;
		if (_loadedThisSession.exists('char:' + charName)) return;

		try
		{
			var path = 'characters/' + charName + '.json';
			if (!Paths.fileExists(path, TEXT)) return;

			var raw:String = Paths.getTextFromFile(path);
			if (raw == null || raw.length == 0) return;

			var data:CharacterFile = cast Json.parse(raw);
			if (data == null) return;

			if (data.image != null && data.image.length > 0)
			{
				var sheets = data.image.split(',');
				for (sheet in sheets)
				{
					var trimmed = sheet.trim();
					if (trimmed.length > 0) cacheGraphic(trimmed);
				}
			}

			if (data.healthicon != null && data.healthicon.length > 0)
				cacheGraphic('icons/icon-' + data.healthicon);

			if (data.noteskin != null && data.noteskin.length > 0)
				preloadNoteSkin(data.noteskin);

			_loadedThisSession.set('char:' + charName, true);
		}
		catch(e:Dynamic) {}
	}

	static function cacheGraphic(key:String):Void
	{
		if (key == null) return;
		var normalized = key.trim();
		if (normalized.length == 0) return;

		if (_loadedThisSession.exists(normalized)) return;

		if (Paths.currentTrackedAssets.exists('images/' + normalized + '.png')) 
		{
			_loadedThisSession.set(normalized, true);
			return;
		}

		if (!Paths.imageExists(normalized)) return;

		var graphic = Paths.image(normalized);
		
		if (graphic != null)
			_loadedThisSession.set(normalized, true);
	}
}
