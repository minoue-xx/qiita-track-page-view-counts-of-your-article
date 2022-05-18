# 閲覧数の確認 Qiita API
Copyright (c) 2022 Michio Inoue.

Qiita に投稿されている特定のアカウントの記事の一覧を Qiita API で取得し、
一定期間中の閲覧数順に並べたものを、Qiita の記事として自動更新するスクリプト。
GitHub Actions で月末に定期実行させます。

実際は [@eigs](https://qiita.com/eigs) の投稿を対象に、結果は
[これまで投稿：閲覧数順一覧](https://qiita.com/eigs/items/ce39353181fee616d52e)
で確認できます。

## 作成環境

 - MATLAB R2022a