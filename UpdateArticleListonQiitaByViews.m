% This script
% 1. extracts the existing items of @eigs (Michio Inoue) posted to Qiita
% 2. checks the view counts since the previous run
% 3. sorts the articles by the view counts
% 4. updates the list of articles on Qiita article
%
% Copyright (c) 2022 Michio Inoue

%% 0. Setup for Qiita API
% Access Token for Qiita API
accessToken=getenv('QIITAACCESSTOKEN'); % assume its set as a env variable.
user_id = "eigs"; % Your id
baseurl = "https://qiita.com/api/v2";
% これまで投稿：閲覧数順一覧 (2022/05/19更新) <- 結果の投稿先
articleuri = 'https://qiita.com/eigs/items/ce39353181fee616d52e';

% Specific Qiita APIs to use.
% see https://qiita.com/api/v2/docs for details
%
% 1. GET /api/v2/users
% - 全てのユーザーの一覧を作成日時の降順で取得します
% 2. PATCH /api/v2/items/:item_id
% - 記事を更新します。
% ref. POST /api/v2/items
% - 新たに記事を作成します。

%% 1. Extract the existing items of @eigs (Michio Inoue) posted to Qiita
disp("Extracting article data started...")

opts = weboptions('HeaderFields',{'Authorization',accessToken});
% per_page is 20 by default
per_page = 20;

index = 1;
item_list = table; % table to add items
nItems = per_page;
while nItems == per_page
    url = baseurl + "/users/" + user_id + "/items?page="...
        + index + "&per_page=" + per_page;
    tmp = webread(url,opts);

    index = index + 1; % counter

    % Keep the subset of information
    id = string(vertcat(tmp.id));
    title = string({tmp.title})';
    tags = {tmp.tags}';
    rendered_body = string({tmp.rendered_body})';
    url = string(vertcat(tmp.url));
    page_views_count = vertcat(tmp.page_views_count);
    likes_count = vertcat(tmp.likes_count);
    created_at = datetime(vertcat(tmp.created_at),...
        'InputFormat', "uuuu-MM-dd'T'HH:mm:ss'+09:00");

    % put them into a table
    nItems = length(id);
    tmp = table(created_at, id, title, tags, likes_count, url, ...
        page_views_count, rendered_body, ...
        'VariableNames',{'created_at','id','title','tags','likes_count','url',...
        'page_views_count','rendered_body'});

    % append
    item_list = [item_list; tmp];
end

%% Keep the first sentence of each article.
firstSentence = strings(height(item_list),1);
for ii=1:height(item_list)
    firstSentence(ii) = getFirstSentence(item_list.rendered_body(ii));
end
item_list.firstSentence = firstSentence;
item_list = removevars(item_list,"rendered_body");

disp("Extracting article data completed.")

%%
viewsHistory = rows2vars(item_list(:,["id","page_views_count"]),...
    'VariableNamesSource','id','VariableNamingRule','preserve');
viewsHistory = removevars(viewsHistory,'OriginalVariableNames');
tViewsHistory = table2timetable(viewsHistory,"RowTimes",datetime);

if ~exist("viewsHistory.csv","file")
    writetimetable(tViewsHistory,"viewsHistory.csv");
    disp("Data is saved to viewsHistory.csv");
    disp("Only one observation is available. Need at least two points...");
    disp("Process Completed.")
    return;
else
    tmp = readtable("viewsHistory.csv",...
        ReadVariableNames=true, VariableNamingRule='preserve');

    % If the datetime string was not correctly parsed (due to locale setting)
    if iscell(tmp.Time)
        tmp.Time = datetime(tmp.Time,'Locale','en_US');
    end
    % add a new data point
    tmp = outerjoin(tmp, timetable2table(tViewsHistory),MergeKeys=true);
    tViewsHistory = table2timetable(tmp,"RowTimes",'Time');
    writetimetable(tViewsHistory,"viewsHistory.csv");
    disp("Data is saved to viewsHistory.csv");
end

%% 2. Check the view counts since the previous run
item_list.dviews = (tViewsHistory{end,:}-tViewsHistory{end-1,:})';
period0 = tViewsHistory.Time(end-1);
period1 = tViewsHistory.Time(end);

% set format for display
period0.Format = "yyyy/MM/dd";
period1.Format = "yyyy/MM/dd";

%% 3. Sort the articles by the view counts since the previous run
item_list = sortrows(item_list,{'dviews','page_views_count'},'descend','MissingPlacement','last');

%% Generate markdown
header = "これまでの投稿を過去一か月の閲覧数順に並べています。" + newline ...
    + "# 集計方法" + newline ...
+ "期間: " + string(period0) + " ~ " + string(period1) + newline ...
+ "対象: @" + user_id + " の投稿" + "（ " + height(item_list) + " 投稿）" + newline ...
+ "詳細: [GitHub: Qiita Track Page View Counts of Your Articles]" ...
+ "(https://github.com/mathworks/qiita-track-page-view-counts-of-your-article)" + newline ...
+ newline ...
+ "作成にあたって以下を参考にいたしました。@kikd さんありがとうございます！" + newline ...
+ " - [GitHub: kikd/matlab-post-qiita](https://github.com/kikd/matlab-post-qiita)" + newline ...
+ " - [Qiita: MATLABでQiitaへ記事を投稿してみた](https://qiita.com/kikd/items/5196b3a46e291a3666fc)";

md = generateMarkdown_ver2(item_list, header);

%% 4. Update the list of articles on Qiita
% Post to Qiita (POST for new article, GET for updating article)
tags = ["matlab" "QiitaAPI" "RestAPI"];
tag_count = length(tags);
if(tag_count > 5)
    error("タグが多すぎます");
end
article_tag = {tag_count};
for i = 1:tag_count
    article_tag{i} = struct('name', tags{i});
    display(article_tag{i})
end

article_title = "これまで投稿：閲覧数順一覧 (" + string(period1) + "更新)";
article_body = struct("body",md, "private", true, ...
    "tags", {article_tag}, "title",article_title, "tweet", false);

%% APIの指定とヘッダの設定
% https://jp.mathworks.com/help/matlab/ref/webwrite.html
% 更新の場合は patch
% POST /api/v2/items

% 最初の方で取得したトークンをAuthorizationヘッダにつける
webopt = weboptions(...
    'ContentType', 'json',...
    'RequestMethod', 'patch', ...
    'HeaderFields', {'Authorization' accessToken}...
    );

try
    response = webwrite(articleuri, article_body, webopt);
    disp("Article updated at" + response.url);
catch ME
    disp("Error: " + ME.identifier);
end

%% generateMarkdown 関数
function md = generateMarkdown_ver2(tData, header)


md = header + newline + newline;
for ii=1:height(tData)
    title = tData.title(ii);
    url = tData.url(ii);
    md = md + "## " + ii + ": [" + title + "]("+url+")" + newline;
    likes = tData.likes_count(ii);
    date = tData.created_at(ii);
    views = tData.page_views_count(ii);
    dviews = tData.dviews(ii);
    date.Format = 'yyyy/MM/dd';

    if isnan(dviews)
        dviews = "NaN";
    end

    md = md + string(date) + " 投稿" + ": **" + string(likes) + "**" + " LGTM" ...
        + newline ...
        + dviews + " views (Total: " + views + " views)" + newline;

    tags = tData.tags{ii};
    tags = string({tags.name});
    tags = "```" + tags + "```";
    md = md + "**Tags** :" + join(tags) + newline;

    summary = tData.firstSentence(ii);
    if strlength(summary) > 150 % 長い要約は打ち切っちゃいます。
        tmp = char(summary);
        summary = string(tmp(1:150)) + "...(中略)";
    end
    md = md + newline + ...
        "> " + summary + newline + newline;
end

end


%% getFirstSentence 関数
function sentence = getFirstSentence(htmlSource)

tree = htmlTree(htmlSource);

% selector = "h1,h2,h3,p,li";
selector = "p,li";
subtrees = findElement(tree,selector);

% check if details contained in p
index = false(length(subtrees),1);
for ii=1:length(subtrees)
    tmp = findElement(subtrees(ii),'details');
    index(ii) = isempty(tmp); % <DETAILS> があれば false になる
end

% DETAILS 無しの P, LI だけ
subtreesNoDetails = subtrees(index);

% 入力文
sentence = extractHTMLText(subtreesNoDetails);

sentence = join(sentence);
tmp = split(sentence(1),'。');
sentence = tmp(1) + "。";

end