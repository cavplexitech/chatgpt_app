# require 'dotenv'
require 'ruby/openai'
require 'csv'
require 'string-similarity'
require 'pdf-reader'

class ChatController < ApplicationController
  def index
    @file = params[:file]
    @success_upload = upload_file(@file) unless @file.nil?
    session[:file] = @file

    @message = params[:message]
    @response = ask_chatgpt(@message) unless @message.nil?

    # @response = ChatgptService.call(@message) unless @message.nil?
  end

  private

  def ask_chatgpt(message)
    openai = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = openai.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: message
      }
    )

    question_embedding = response['data'][0]['embedding']

    similarity_array = []

    CSV.foreach(Rails.root.join('app', 'training-data', 'embeddings.csv'), headers: true) do |row|

      text_embedding = JSON.parse(row['embedding'])

      similarity_array << String::Similarity.cosine(question_embedding, text_embedding)
    end
    index_of_max = similarity_array.index(similarity_array.max)

    original_text = ''

    CSV.foreach(Rails.root.join('app', 'training-data', 'embeddings.csv'), headers: true).with_index do |row, rowno|
      original_text = row['text'] if rowno == index_of_max
    end

    prompt =
      "You are an AI assistant. You work for CDAsia Technologies, which is a storer of all
    the laws of the Philippines. You will be asked questions from a
    user and will answer in a helpful and friendly manner.

    You will be provided information from documents under the
    [Article] section. The user question will be provided under the
    [Question] section. You will answer the customers questions based on the
    article.

    If the users question is not answered by the article you will respond with
    'I'm sorry I don't know.'

    [Article]
    #{original_text}

    [Question]
    #{message}"

    response = openai.completions(
      parameters: {
        model: 'text-davinci-003',
        prompt: prompt + '\n',
        temperature: 0.2,
        max_tokens: 500,
        stop: ["\\n"]
      }
    )

    response['choices'][0]['text'].lstrip
  end

  def upload_file(file_path)
    openai = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    text_array = []

    File.open(Rails.root.join('app', 'training-data', 'train.txt'), 'w') { |file| file.truncate(0) } if File.exists?(Rails.root.join('app', 'training-data', 'train.txt'))

    PDF::Reader.open(Rails.root.join(file_path)) do |reader|
      reader.pages.each do |page|
        File.write(Rails.root.join('app', 'training-data', 'train.txt'), page, mode: 'a')
      end
    end

    # File.foreach(Rails.root.join('app', 'training-data', 'train.txt')) { |line| puts line }

    Dir.glob(Rails.root.join('app', 'training-data', 'train.txt')) do |file|
      file_chunks = File.read(file).dump.scan(/.{1,4096}/)
      file_chunks.each do |chunk|
        text_array << chunk
      end
    end

    embedding_array = []

    text_array.each do |text|
      response = openai.embeddings(
        parameters: {
          model: 'text-embedding-ada-002',
          input: text
        }
      )

      embedding = response['data'][0]['embedding']

      embedding_hash = { embedding: embedding, text: text }
      embedding_array << embedding_hash
    end

    CSV.open(Rails.root.join('app', 'training-data', 'embeddings.csv'), 'w') do |csv|
      csv << %i[embedding text]
      embedding_array.each do |obj|
        csv << [obj[:embedding], obj[:text]]
      end
    end

    'Successfully uploaded file!'
    # text = ''

    # PDF::Reader.open(Rails.root.join(file_path)) do |reader|
    #   reader.pages.each do |page|
    #     text << page.text
    #   end
    # end

    # split_text = text.scan(/.{1,4096}/)

    # split_text.each do |chunk|
    #   ChatgptService.call(chunk)
    # end
  end
end
