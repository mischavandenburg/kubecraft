---
title: Adding an Author Profile to Your Blog
hide:
  - toc
tags:
  - guideline
  - blog
---

Did you know we also write blogs? Our team is passionate about creating content that inspires others to learn and grow. If you share this passion, we’d love to have you join us.

As an author, your hard work deserves recognition. This article will guide you on how to tag yourself as the author of a blog, ensuring you get the credit you deserve.

## Step 1

Open the file located at `docs/blog/.authors.yml`. You will see that we already have a few authors in there. To join the list, create a new entry.

```yaml
authors:
  HYP3R00T: #Your GitHub Handle
    name: Rajesh Kumar Das # Your display name
    description: Contributor # Describe yourself
    avatar: https://avatars.githubusercontent.com/u/78068806?v=4 # Link to your GitHub avatar
    url: https://github.com/HYP3R00T # Link to your GitHub profile
```

_Note: Make sure you indent your entry properly._

## Step 2

Now, it's time to tag yourself as the author of a blog. In the blog post, within the frontmatter, put your name under `authors`.

```yaml
---
authors:
  - HYP3ROOT # Your GitHub Handle
---
# Post Content
```

To learn more about it, check out [built-in blog plugin](https://squidfunk.github.io/mkdocs-material/plugins/blog/#meta.authors).
