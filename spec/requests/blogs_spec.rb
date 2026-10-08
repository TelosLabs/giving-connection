require "rails_helper"

RSpec.describe "Blogs", type: :request do
  describe "GET /index" do
    it "shows only published blogs" do
      published = create(:blog, title: "Published Story", published: true)
      create(:blog, title: "Draft Story", published: false)

      get blogs_path

      expect(response.body).to include(published.title)
      expect(response.body).not_to include("Draft Story")
    end

    # Regression guard: the "All posts (N)" badge used to be computed from
    # the unfiltered Blog.published scope regardless of the search box, so it
    # never matched what was actually on the page once a user searched.
    it "updates the All posts count to reflect the search, not the unfiltered total" do
      create(:blog, title: "Findable Zyxqrt Story", published: true)
      create(:blog, title: "Unrelated Story", published: true)

      get blogs_path, params: {q: "Zyxqrt"}

      expect(response.body).to include("All posts (1)")
      expect(response.body).to include("Findable Zyxqrt Story")
      expect(response.body).not_to include("Unrelated Story")
    end

    it "matches on title, topic, author name, and content" do
      by_title = create(:blog, title: "Wxvutsr in the title", published: true)
      by_topic = create(:blog, title: "Other", topic: "Wxvutsr topic", published: true)
      by_author = create(:blog, title: "Other 2", user: create(:user, name: "Wxvutsr Author"), published: true)
      by_content = create(:blog, title: "Other 3", content: "Body mentions Wxvutsr here", published: true)
      unrelated = create(:blog, title: "Totally unrelated", published: true)

      get blogs_path, params: {q: "Wxvutsr"}

      [by_title, by_topic, by_author, by_content].each do |blog|
        expect(response.body).to include(blog.title)
      end
      expect(response.body).not_to include(unrelated.title)
    end

    it "escapes ILIKE wildcard characters in the search term" do
      create(:blog, title: "Has 100% coverage", published: true)
      create(:blog, title: "Should not match", published: true)

      get blogs_path, params: {q: "100%"}

      expect(response.body).to include("Has 100% coverage")
      expect(response.body).not_to include("Should not match")
    end

    it "combines the tag filter and the search term" do
      matching = create(:blog, title: "Zyxqrt Nonprofit Story", blog_tag: "Nonprofits", published: true)
      wrong_tag = create(:blog, title: "Zyxqrt Community Story", blog_tag: "Community", published: true)

      get blogs_path, params: {blog_tag: "Nonprofits", q: "Zyxqrt"}

      expect(response.body).to include(matching.title)
      expect(response.body).not_to include(wrong_tag.title)
      # Both blogs match the search term; "All posts" is tag-agnostic, so it
      # should count both even though the Nonprofits tab itself shows one.
      expect(response.body).to include("All posts (2)")
      expect(response.body).to include("Nonprofits (1)")
    end

    it "shows an empty state instead of blog cards when nothing matches" do
      create(:blog, title: "Does not match", published: true)

      get blogs_path, params: {q: "Zyxqrt"}

      expect(response.body).to include("No blog posts match your search")
    end

    # The search box, the tab links, and the result count must all survive a
    # tab switch so the user doesn't lose their search by clicking a tab.
    it "preserves the search term in the input value and in the tab links" do
      create(:blog, title: "Zyxqrt Story", blog_tag: "Nonprofits", published: true)

      get blogs_path, params: {blog_tag: "Nonprofits", q: "Zyxqrt"}

      expect(response.body).to include('value="Zyxqrt"')
      expect(response.body).to include("blog_tag=Community&amp;q=Zyxqrt")
    end

    it "renders the results inside a turbo-frame so tab/search navigation stays in place" do
      get blogs_path

      expect(response.body).to include("<turbo-frame")
      expect(response.body).to include('id="blog-search"')
      expect(response.body).to include('data-turbo-action="advance"')
    end

    # Regression guard: the search <form>/<input> must stay OUTSIDE the
    # "blog-search" turbo-frame it targets, not inside it. Turbo replaces a
    # frame's entire DOM subtree on every navigation that updates it -- if
    # the input lived inside, every debounced search (i.e. whenever the user
    # paused typing) destroyed and recreated the focused input out from under
    # the browser's in-progress text entry, corrupting what was typed
    # (dropped characters, reordered letters), not just losing focus.
    it "keeps the search form outside the turbo-frame it targets" do
      get blogs_path

      form_index = response.body.index("<form")
      frame_index = response.body.index("<turbo-frame")

      expect(form_index).to be < frame_index
      expect(response.body).to include('data-turbo-frame="blog-search"')
    end
  end
end
