# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/callbacks'

class Flame
  def call(env)
    env['flame'] = 'F Lifo..'
  end
end

class Pacify
  def initialize(with)
    @with = with
  end

  def call(env)
    env['peace'] = @with
  end
end

class Finale
  def call(response)
    status, headers, body = response

    headers['last'] = 'Finale'
    $old_status = status

    [201, headers, body]
  end
end

class TheEnd
  def call(response)
    status, headers, body = response

    headers['last'] = 'TheEnd'
    [201, headers, body]
  end
end

describe "Rack::Callbacks" do
  specify "works for love and small stack trace" do
    callback_app = Rack::Callbacks.new do
      before Flame
      before Pacify, "with love"

      run lambda {|env| [200, {}, [env['flame'], env['peace']]] }

      after Finale
      after TheEnd
    end

    app = Rack::Lint.new(
      Rack::Builder.new do
        run callback_app
      end.to_app
    )

    response = Rack::MockRequest.new(app).get("/")

    _(response.body).must_equal 'F Lifo..with love'

    _($old_status).must_equal 200
    _(response.status).must_equal 201

    _(response.headers['last']).must_equal 'TheEnd'
  end
end
