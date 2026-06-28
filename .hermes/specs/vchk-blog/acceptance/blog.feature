Feature: vchk Blog Accessibility

  Scenario: Homepage loads with post list
    Given a visitor navigates to https://vchk.eu
    When the page loads
    Then the response status is 200
    And the page contains at least one blog post entry
    And the page does NOT contain the word "vichoko"

  Scenario: Individual post renders correctly
    Given a post with slug "hello-world" exists
    When a visitor navigates to /posts/hello-world/
    Then the response status is 200
    And the page shows the post title, date, and body content

  Scenario: RSS feed is accessible
    Given a blog with published posts
    When a visitor requests /atom.xml
    Then the response status is 200
    And the content-type is XML
    And the feed contains at least one entry

  Scenario: Tag index page works
    Given a post tagged "cli" exists
    When a visitor navigates to /tags/cli/
    Then the response status is 200
    And the page lists all posts with that tag

  Scenario: No personal identity exposed
    Given a visitor browses any page on vchk.eu
    When the page content is searched
    Then it contains zero matches for the following terms
      """
      vichoko
      uber
      applied scientist
      santiago
      """
    And no link to "vichoko.cl" is present

  Scenario: HTTPS enforced
    Given a visitor requests http://vchk.eu
    When the request is processed
    Then they are redirected to https://vchk.eu

  Scenario: WHOIS privacy
    Given a WHOIS lookup is performed on vchk.eu
    When the lookup completes
    Then registrant information is redacted or not disclosed

  Scenario: Empty blog shows placeholder
    Given a fresh blog deployment with zero posts
    When a visitor loads the homepage
    Then the page shows "No posts yet" or equivalent placeholder

  Scenario: Post with no tags renders
    Given a post without any tags
    When the post page renders
    Then no tag section or tag-related error appears

  Scenario: 404 for unknown pages
    Given a visitor navigates to /nonexistent-page
    When the request is processed
    Then the response status is 404

  Scenario: No analytics scripts present
    Given a visitor loads any page on vchk.eu
    When the HTML source is inspected
    Then there are no <script> tags pointing to google-analytics.com, plausible.io, or any external analytics service

  Scenario: Responsive viewport meta tag
    Given a visitor loads any page on vchk.eu on a mobile device
    When the page HTML is inspected
    Then the <head> contains a <meta name="viewport"> tag

  Scenario: Build failures do not deploy stale content
    Given a Zola build fails (non-zero exit code)
    When the GHA workflow runs
    Then the deployment step is skipped
    And the GCS bucket retains its previous content unchanged

  Scenario: No origin IP exposed
    Given a visitor performs a DNS lookup on vchk.eu
    When the DNS records are inspected
    Then only Cloudflare IP addresses are visible
    And no raw GCS bucket IP or CNAME is directly exposed

  Scenario: Content review gate before merge
    Given a new blog post is submitted for review
    When the pre-merge checklist runs
    Then the post is checked for accidental personal references
    And the post is checked for cross-links to vichoko.cl
    And deployment is blocked unless all checks pass
