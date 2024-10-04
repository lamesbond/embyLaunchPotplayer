// noinspection LossyEncoding

bool debug = false;
void OnInitialize() {
	if (debug) {
		HostOpenConsole();
	}

}

string GetTitle() {
	return "Emby";
}
string GetVersion() {
	return "1.2";
}

string GetDesc() {
	return "localhost:8096";
}

string HOST;
string ITEMID;
string APIKEY;
//需事先填入emby用户ID
string USERID = "350f66890abd42ce8e7073b7e1f01655";
string ITEMTYPE = "movie";


string post(string url, string data="") {
	string UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36";
	string Headers;
	Headers = "";

	return HostUrlGetStringWithAPI(url, UserAgent, Headers, data, true);
}
string VideoUrl(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
    array<dictionary> subtitle;
    dictionary dic;
	string currentItemId = HostRegExpParse(path, "videos/([0-9]+)/");

//获取item详情
    string url = HOST + "/emby/Users/" + USERID + "/Items/" + currentItemId + "?api_key=" + APIKEY;
    string res = post(url);

    if (!res.empty()) {
		JsonReader Reader;
		JsonValue Root;
		if (Reader.parse(res, Root) && Root.isObject()) {
			JsonValue mediaSource = Root["MediaSources"][0];
			
			if (ITEMTYPE == "movie") {
				HostPrintUTF8("修改电影标题：" + Root["FileName"].asString());
				string streamUrl = HostRegExpParse(path, "([^&]+)/userid=");
                MetaData["title"] = Root["FileName"].asString();
			    MetaData["SourceUrl"] = path;
			}
			
			for (int i = 0; i < mediaSource["MediaStreams"].size(); i++) {
            	JsonValue mediaStream = mediaSource["MediaStreams"][i];
            	if (mediaStream.isObject()) {
            	    if (mediaStream["Type"].asString() == "Subtitle" && mediaStream["IsExternal"].asString() == "true") {
            	        dic["name"] = mediaStream["DisplayTitle"].asString() + " 外挂";
            	        dic["url"] = HOST + "/emby/videos/" + currentItemId + "/" + mediaSource["Id"].asString() + "/Subtitles/" + mediaStream["Index"].asString() + "/Stream." + mediaStream["codec"].asString() + "?api_key=" + APIKEY;
            	    }
            	}
            	subtitle.insertLast(dic);
            }

            MetaData["subtitle"] = subtitle;
		}
	}
	return path;
}
array<dictionary> VideosUrl(const string &in path) {
    string seriesid;
	string seasonid;
    string url;
    string res;
    array<dictionary> episodes;

//获取item详情，取seriesid和seasonid，绝命毒师整个系列为一个seriesid，5季对应5个seasonid
    url = HOST + "/emby/Users/" + USERID + "/Items/" + ITEMID + "?api_key=" + APIKEY;
    res = post(url);
    if (!res.empty()) {
		JsonReader Reader;
		JsonValue Root;
		if (Reader.parse(res, Root) && Root.isObject()) {
			seriesid = Root["SeriesId"].asString();
			// 判断是不是要插入正剧前后播放的特典，OVA之类，如果是，将按季1，季2的顺序添加，而不是按Special季的顺序
			if (!Root["SortParentIndexNumber"].isNull()) {
				int sortParentIndexNumber = Root["SortParentIndexNumber"].asInt();
                url = HOST + "/emby/Shows/" + seriesid + "/Seasons?api_key=" + APIKEY;
				res = post(url);
				if (!res.empty()) {
					if (Reader.parse(res, Root) && Root.isObject()) {
                        for (int i = 0; i < Root["Items"].size(); i++) {
					        JsonValue season = Root["Items"][i];
					        if (season.isObject() && season["IndexNumber"].asInt() == sortParentIndexNumber) {
                                seasonid = season["Id"].asString();
					        }
				        }
					}
				}
			} else {
				seasonid = Root["SeasonId"].asString();
			}
		}
	}
	HostPrintUTF8("获取到的seriesid：" + seriesid + "seasonid：" + seasonid);
//获取seasonid下所有的episode
    url = HOST + "/emby/Shows/" + seriesid + "/Episodes?SeasonId=" + seasonid + "&api_key=" + APIKEY;
    res = post(url);
    if (!res.empty()) {
		JsonReader Reader;
		JsonValue Root;
		if (Reader.parse(res, Root) && Root.isObject()) {
            JsonValue eitems = Root["Items"];
			if (eitems.isArray()) {
				int pos;
				for (int i = 0; i < eitems.size(); i++) {
					JsonValue eitem = eitems[i];
					if (eitem.isObject()) {
						if (eitem["Id"].asString() == ITEMID) {
                            pos = i;
						}
					 }
				}
				for (int i = pos; i < eitems.size(); i++) {
					JsonValue eitem = eitems[i];
					if (eitem.isObject()) {
					 	dictionary episode;
                        url = HOST + "/emby/Users/" + USERID + "/Items/" + eitem["Id"].asString() + "?api_key=" + APIKEY;
                        string childres = post(url);
                        if (!childres.empty()) {
                        	JsonReader ChildReader;
                         	JsonValue ChildRoot;
                        	if (ChildReader.parse(childres, ChildRoot) && ChildRoot.isObject()) {
                        	    episode["title"] =ChildRoot["FileName"].asString();;
		                        episode["url"] = HOST + "/emby/videos/" + eitem["Id"].asString() + "/stream." + ChildRoot["MediaSources"][0]["Container"].asString() + "?api_key=" + APIKEY + "&Static=true&MediaSourceId=" + ChildRoot["MediaSources"][0]["Id"].asString();
                           }
                        }

					 	episodes.insertLast(episode);
					 }
				}
			}
		}
	}

	return episodes;
}

bool PlayitemCheck(const string &in path) {
	if (HOST.empty()) {
        HOST = HostRegExpParse(path, "([^&]+)/emby/");
		HostPrintUTF8("重要参数HOST获取：" + HOST);
	}
	if (ITEMID.empty()) {
        ITEMID = HostRegExpParse(path, "videos/([0-9]+)/");
		HostPrintUTF8("重要参数ITEMID获取：" + ITEMID);
	}
	if (APIKEY.empty()) {
        APIKEY = HostRegExpParse(path, "api_key=([a-zA-Z0-9]+)&Static");
		HostPrintUTF8("重要参数APIKEY获取：" + APIKEY);
	}
	if (USERID.empty()) {
        USERID = HostRegExpParse(path, "userid=([a-zA-Z0-9]+)");
		HostPrintUTF8("重要参数USERID获取：" + USERID);
	}
    HostPrintUTF8("playitemcheck开始");
    if (path.find("emby") >= 0) {
		return true;
	}

	return false;
}

bool PlaylistCheck(const string &in path) {
	if (path.find("emby") < 0) {
		return false;
	}
	HostPrintUTF8("playlistcheck开始");

//获取item详情
    string url = HOST + "/emby/Users/" + USERID + "/Items/" + ITEMID + "?api_key=" + APIKEY;
    string res = post(url);

    if (!res.empty()) {
		JsonReader Reader;
		JsonValue Root;
		if (Reader.parse(res, Root) && Root.isObject()) {
            if (Root["Type"].asString() == "Episode") {
				HostPrintUTF8("playlistcheck为episode");
				ITEMTYPE = "episode";
                return true;
            }
		}
	}

	return false;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	HostPrintUTF8("playitemparse开始");
	if (path.find("/videos") >= 0) {
        return VideoUrl(path, MetaData, QualityList);
	}

	return path;
}

array<dictionary> PlaylistParse(const string &in path) {
	HostPrintUTF8("playlistparse开始");
	return VideosUrl(path);
}
