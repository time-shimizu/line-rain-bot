desc 'This task is called by the Heroku scheduler add-on'
task :update_feed => :environment do
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  }

  # 使用したxmlデータ（毎日朝6時更新）：以下URLを入力すれば見ることができます。
  url  = 'https://www.drk7.jp/weather/xml/13.xml'
  # xmlデータをパース（利用しやすいように整形）
  xml  = open( url ).read.toutf8

  doc = REXML::Document.new(xml)
  colona_doc = REXML::Document.new(colona_xml)
  # パスの共通部分を変数化（area[4]は「東京地方」を指定している）
  xpath = 'weatherforecast/pref/area[4]/info/rainfallchance/'
  # 6時〜12時の降水確率（以下同様）
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  # メッセージを発信する降水確率の下限値の設定
  min_per = 50
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word_1 =
      ["あかん、優勝してまう",
       "おはようさん",
       "そろそろサウナいこや",
       "サトテル最高や！"].sample
    word_2 =
      ["ほなまた",
       "良い一日過ごしや〜",
       "また合コン決まったら連絡するわな"].sample
    # 降水確率によってメッセージを変更する閾値の設定
    mid_per = 70
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
      word_3 = "雨ふるかもやから傘持ってきや"
    else
      word_3 = "折り畳み傘あってもええかもな"
    end
    # 発信するメッセージの設定
    push =
      "ワイはもうワクチン打ったやで!\n #{word_1}\n#{word_3}\n降水確率はこんな感じやで。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word_2}"
    # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
end
