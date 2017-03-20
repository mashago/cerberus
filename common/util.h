
#ifndef __UTIL_H__
#define __UTIL_H__

// clear pointer container
template <typename TP, template <typename E, typename Alloc = std::allocator<E>> class TC>
void ClearContainer(TC<TP> &c)
{
	while (!c.empty())
	{
		auto iter = c.begin();
		delete *iter;
		*iter = nullptr;
		c.erase(iter);
	}
}

#endif
