import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { next } from "@ember/runloop";
import { ajax } from "discourse/lib/ajax";
import { getURLWithCDN } from "discourse/lib/get-url";
import icon from "discourse/helpers/d-icon";

export default class CategoryMemberDirectory extends Component {
  @tracked members = [];
  @tracked isLoading = true;
  @tracked error = null;
  @tracked totalMembers = 0;
  @tracked currentPage = 1;
  @tracked isExpanded = false;
  
  _loadedCategoryId = null;

  // Number of members to show in collapsed (1 row) state
  get collapsedCount() {
    return 6;
  }

  // Number of members per page when expanded (roughly 3 rows)
  get expandedCount() {
    return settings.members_per_page || 18;
  }

  get category() {
    return this.args.outletArgs?.category;
  }

  get categoryId() {
    return this.category?.id;
  }

  get groupName() {
    const category = this.category;
    if (!category) return null;

    // Manual mapping takes priority
    const mapping = settings.category_group_mapping;
    if (mapping) {
      const pairs = mapping.split("|");
      for (const pair of pairs) {
        const [categoryId, groupName] = pair.split(":").map((s) => s.trim());
        if (parseInt(categoryId, 10) === category.id) {
          return groupName;
        }
      }
    }

    // Auto-match by slug (default)
    if (settings.auto_match_by_slug && category.slug) {
      const prefix = settings.group_slug_prefix || "";
      const suffix = settings.group_slug_suffix || "";
      return `${prefix}${category.slug}${suffix}`;
    }

    return null;
  }

  get shouldShow() {
    // Trigger reload if category changed
    if (this.categoryId && this._loadedCategoryId !== this.categoryId) {
      next(this, this.reload);
    }
    return this.groupName && (this.members.length > 0 || this.isLoading);
  }

  get displayedMembers() {
    if (!this.isExpanded) {
      return this.members.slice(0, this.collapsedCount);
    }
    return this.members;
  }

  get hasMoreThanCollapsed() {
    return this.totalMembers > this.collapsedCount;
  }

  get showViewMore() {
    return !this.isExpanded && this.hasMoreThanCollapsed;
  }

  get cardTitle() {
    const title = settings.card_title || "Members";
    if (settings.show_member_count && this.totalMembers > 0) {
      return `${title} (${this.totalMembers})`;
    }
    return title;
  }

  get perPage() {
    return this.expandedCount;
  }

  get totalPages() {
    return Math.ceil(this.totalMembers / this.perPage);
  }

  get hasPrevPage() {
    return this.currentPage > 1;
  }

  get hasNextPage() {
    return this.currentPage < this.totalPages;
  }

  get showPagination() {
    return this.isExpanded && this.totalPages > 1;
  }

  @action
  expand() {
    this.isExpanded = true;
    // Load full first page if we only had collapsed data
    if (this.members.length <= this.collapsedCount) {
      this.loadMembers(1);
    }
  }

  @action
  reload() {
    if (this._loadedCategoryId === this.categoryId) return;
    this._loadedCategoryId = this.categoryId;
    this.currentPage = 1;
    this.isExpanded = false;
    this.loadMembers();
  }

  @action
  async loadMembers(page = 1) {
    const groupName = this.groupName;
    if (!groupName) {
      this.isLoading = false;
      return;
    }

    try {
      this.isLoading = true;
      this.error = null;

      const offset = (page - 1) * this.perPage;
      const response = await ajax(`/groups/${groupName}/members.json`, {
        data: { offset, limit: this.perPage, order: "", asc: true },
      });

      this.members = response.members || [];
      this.totalMembers = response.meta?.total || this.members.length;
      this.currentPage = page;
    } catch (e) {
      console.error("Failed to load group members:", e);
      this.error = "Unable to load members";
      this.members = [];
    } finally {
      this.isLoading = false;
    }
  }

  @action
  prevPage() {
    if (this.hasPrevPage) {
      this.loadMembers(this.currentPage - 1);
    }
  }

  @action
  nextPage() {
    if (this.hasNextPage) {
      this.loadMembers(this.currentPage + 1);
    }
  }

  getAvatarUrl(member, size = 45) {
    if (!member.avatar_template) return "";
    return getURLWithCDN(member.avatar_template.replace("{size}", size));
  }

  <template>
    {{#if this.shouldShow}}
      <div class="category-member-directory">
        <div class="member-directory-header">
          <h3 class="member-directory-title">{{this.cardTitle}}</h3>
        </div>

        {{#if this.isLoading}}
          <div class="member-directory-loading">
            <div class="spinner"></div>
            <span>Loading members...</span>
          </div>
        {{else if this.error}}
          <div class="member-directory-error">
            {{this.error}}
          </div>
        {{else}}
          <div class="member-directory-grid">
            {{#each this.displayedMembers as |member|}}
              <a
                href="/u/{{member.username}}"
                class="member-card"
                title="{{member.name}}"
              >
                <img
                  src={{this.getAvatarUrl member}}
                  alt="{{member.username}}"
                  class="member-avatar"
                  loading="lazy"
                />
                {{#if settings.show_member_names}}
                  <div class="member-name">{{member.name}}</div>
                {{/if}}
              </a>
            {{/each}}
          </div>

          {{#if this.showViewMore}}
            <div class="member-directory-footer">
              <button
                type="button"
                class="view-more-btn"
                {{on "click" this.expand}}
              >
                View all {{this.totalMembers}} members
              </button>
            </div>
          {{else if this.showPagination}}
            <div class="member-directory-footer">
              <div class="member-directory-pagination">
                <button
                  type="button"
                  class="pagination-btn prev-page"
                  disabled={{unless this.hasPrevPage "disabled"}}
                  {{on "click" this.prevPage}}
                  title="Previous page"
                >
                  {{icon "chevron-left"}}
                </button>

                <span class="pagination-info">
                  {{this.currentPage}} / {{this.totalPages}}
                </span>

                <button
                  type="button"
                  class="pagination-btn next-page"
                  disabled={{unless this.hasNextPage "disabled"}}
                  {{on "click" this.nextPage}}
                  title="Next page"
                >
                  {{icon "chevron-right"}}
                </button>
              </div>
            </div>
          {{/if}}
        {{/if}}
      </div>
    {{/if}}
  </template>
}
