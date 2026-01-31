import { apiInitializer } from "discourse/lib/api";
import CategoryMemberDirectory from "../components/category-member-directory";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet("discovery-list-container-top", CategoryMemberDirectory);
});
